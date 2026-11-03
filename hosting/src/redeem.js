(() => {
  'use strict';

  const ENDPOINT = '/api/premium/redeem';
  const MONTHS = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  const RESULTS = ['redeemed', 'alreadyRedeemed'];
  const REFUSALS = [
    'codeUnknown',
    'codeNotStarted',
    'codeExpired',
    'codePaused',
    'codeUsedUp',
    'badEmail',
    'badCode',
  ];

  const form = document.getElementById('redeem-form');
  const status = document.getElementById('redeem-status');
  if (form === null || status === null) return;

  const button = form.querySelector('button[type="submit"]');
  const idleLabel = button.textContent;
  const sendingLabel = button.getAttribute('data-sending-label') ?? idleLabel;
  let sending = false;

  form.hidden = false;

  function show(state) {
    for (const notice of status.querySelectorAll(':scope > [data-state]')) {
      notice.hidden = notice.getAttribute('data-state') !== state;
    }
    if (state !== null) status.focus();
  }

  function fill(name, text) {
    for (const slot of status.querySelectorAll(`[data-fill="${name}"]`)) slot.textContent = text;
  }

  function readableDate(isoDate) {
    const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(typeof isoDate === 'string' ? isoDate : '');
    if (match === null) return null;
    const month = MONTHS[Number(match[2]) - 1];
    if (month === undefined) return null;
    return `${String(Number(match[3]))} ${month} ${match[1]}`;
  }

  function fillDate(state, name, isoDate) {
    const date = readableDate(isoDate);
    const notice = status.querySelector(`[data-state="${state}"]`);
    notice.querySelector('[data-when]').hidden = date === null;
    fill(name, date ?? '');
  }

  function amountText(days) {
    return `${String(days)} ${days === 1 ? 'day' : 'days'} of Premium`;
  }

  async function redeem(code, email) {
    if (!navigator.onLine) return 'offline';
    let response;
    try {
      response = await fetch(ENDPOINT, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ code, email }),
        credentials: 'omit',
        cache: 'no-store',
      });
    } catch {
      return navigator.onLine ? 'unavailable' : 'offline';
    }
    if (response.status === 429) return 'tooMany';
    const data = await response.json().catch(() => null);
    if (data === null || typeof data !== 'object') return 'unavailable';

    if (response.ok) {
      if (!RESULTS.includes(data.result) || !Number.isInteger(data.days) || data.days <= 0) {
        return 'unavailable';
      }
      fill('amount', amountText(data.days));
      fill('email', email);
      return data.result;
    }
    if (!REFUSALS.includes(data.error)) return 'unavailable';
    if (data.error === 'codeNotStarted') fillDate('codeNotStarted', 'startsOn', data.startsOn);
    if (data.error === 'codeExpired') fillDate('codeExpired', 'endedOn', data.endedOn);
    return data.error;
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

    const code = form.elements.namedItem('code').value;
    const email = form.elements.namedItem('email').value.trim();

    show(null);
    setSending(true);
    const state = await redeem(code, email);
    setSending(false);
    if (RESULTS.includes(state)) form.hidden = true;
    show(state);
  });
})();
