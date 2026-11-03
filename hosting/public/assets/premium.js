(() => {
  'use strict';

  const LOOKUP = '/api/premium/gift/lookup';
  const REASSIGN = '/api/premium/gift/reassign';
  const DAYS_PER_MONTH = 31;
  const FRAME_SIZES = { 'frame-10': '10-inch frame', 'frame-15': '15-inch frame' };
  const LOOKUP_STATES = ['waiting', 'claimed', 'void'];
  const REFUSALS = {
    voucherNotFound: 'notFound',
    voucherClaimed: 'claimed',
    voucherVoid: 'void',
    badEmail: 'badEmail',
    voucherReassignLimit: 'reassignLimit',
    tooManyTries: 'tooMany',
  };

  const status = document.getElementById('gift-status');
  const form = document.getElementById('gift-form');
  const formStatus = document.getElementById('gift-form-status');
  if (status === null || form === null || formStatus === null) return;

  const button = form.querySelector('button[type="submit"]');
  const idleLabel = button.textContent;
  const sendingLabel = button.getAttribute('data-sending-label') ?? idleLabel;
  let sending = false;

  function show(region, state, focus) {
    for (const notice of region.querySelectorAll(':scope > [data-state]')) {
      notice.hidden = notice.getAttribute('data-state') !== state;
    }
    if (focus && state !== null) region.focus();
  }

  function showGift(state, focus) {
    show(status, state, focus);
    form.hidden = state !== 'waiting';
  }

  function tokenFromPath(path) {
    const match = /^\/premium\/([A-Za-z0-9_-]{43})\/?$/.exec(path);
    return match === null ? null : match[1];
  }

  function amountText(days) {
    if (days % DAYS_PER_MONTH === 0) {
      const months = days / DAYS_PER_MONTH;
      return `${String(months)} ${months === 1 ? 'month' : 'months'} of Premium`;
    }
    return `${String(days)} ${days === 1 ? 'day' : 'days'} of Premium`;
  }

  async function post(path, body) {
    if (!navigator.onLine) return { state: 'offline' };
    let response;
    try {
      response = await fetch(path, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
        credentials: 'omit',
        cache: 'no-store',
        referrerPolicy: 'no-referrer',
      });
    } catch {
      return { state: navigator.onLine ? 'unavailable' : 'offline' };
    }
    if (response.status === 429) return { state: 'tooMany' };
    const data = await response.json().catch(() => null);
    if (data === null || typeof data !== 'object') return { state: 'unavailable' };
    if (response.ok) return { state: 'ok', data };
    return { state: REFUSALS[data.error] ?? 'unavailable' };
  }

  function isLookup(data) {
    return (
      LOOKUP_STATES.includes(data.status) &&
      Number.isInteger(data.days) &&
      data.days > 0 &&
      typeof data.emailMasked === 'string'
    );
  }

  const token = tokenFromPath(window.location.pathname);

  async function lookUp(focus) {
    showGift('loading', focus);
    const result = await post(LOOKUP, { token });
    if (result.state !== 'ok') {
      showGift(result.state === 'badEmail' ? 'unavailable' : result.state, focus);
      return;
    }
    if (!isLookup(result.data)) {
      showGift('unavailable', focus);
      return;
    }
    document.getElementById('gift-amount').textContent = amountText(result.data.days);
    document.getElementById('gift-frame').textContent = FRAME_SIZES[result.data.sku] ?? 'frame';
    document.getElementById('gift-email').textContent = result.data.emailMasked;
    showGift(result.data.status, focus);
  }

  function setSending(isSending) {
    sending = isSending;
    button.disabled = isSending;
    button.textContent = isSending ? sendingLabel : idleLabel;
  }

  form.addEventListener('submit', async (event) => {
    event.preventDefault();
    if (sending) return;
    if (!form.reportValidity()) return;

    const input = form.elements.namedItem('email');
    show(formStatus, null, false);
    setSending(true);
    const result = await post(REASSIGN, { token, email: input.value.trim() });
    setSending(false);

    if (result.state === 'ok' && typeof result.data.emailMasked === 'string') {
      document.getElementById('gift-email').textContent = result.data.emailMasked;
      document.getElementById('gift-sent-email').textContent = result.data.emailMasked;
      input.value = '';
      show(formStatus, 'sent', true);
      return;
    }
    if (result.state === 'notFound' || result.state === 'claimed' || result.state === 'void') {
      showGift(result.state, true);
      return;
    }
    show(formStatus, result.state === 'ok' ? 'unavailable' : result.state, true);
  });

  for (const retry of status.querySelectorAll('[data-retry]')) {
    retry.addEventListener('click', () => {
      void lookUp(true);
    });
  }

  if (token === null) {
    showGift('notFound', false);
    return;
  }
  void lookUp(false);
})();
