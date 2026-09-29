// The deletion request form on /delete-account. It sends one JSON request to
// `requestAccountDeletion` (through the hosting rewrite) and shows which of the
// contract's answers came back. The words for every state are in the page, not
// here, so this file only chooses which to show.
//
//   202 {"status":"received"}   400 {"status":"invalid"}
//   429 {"status":"tooMany"}    anything else, or no answer: unavailable/offline
(() => {
  'use strict';

  const ENDPOINT = '/api/account-deletion-request';
  const form = document.getElementById('deletion-form');
  const status = document.getElementById('deletion-status');
  if (form === null || status === null) return;

  const button = form.querySelector('button[type="submit"]');
  const idleLabel = button.textContent;
  const sendingLabel = button.getAttribute('data-sending-label') ?? idleLabel;
  let sending = false;

  // Without JavaScript the form stays hidden and the <noscript> notice names
  // the address to write to instead.
  form.hidden = false;

  function show(state) {
    for (const notice of status.querySelectorAll('[data-state]')) {
      notice.hidden = notice.getAttribute('data-state') !== state;
    }
    if (state !== null) status.focus();
  }

  function stateFor(response) {
    if (response.status === 202) return 'received';
    if (response.status === 400) return 'invalid';
    if (response.status === 429) return 'tooMany';
    return 'unavailable';
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
    if (!navigator.onLine) {
      show('offline');
      return;
    }

    const email = form.elements.namedItem('email').value.trim();
    const message = form.elements.namedItem('message').value.trim();
    const body = message === '' ? { email } : { email, message };

    show(null);
    setSending(true);
    let state;
    try {
      const response = await fetch(ENDPOINT, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
        credentials: 'omit',
      });
      state = stateFor(response);
    } catch {
      state = navigator.onLine ? 'unavailable' : 'offline';
    }
    setSending(false);
    if (state === 'received') form.hidden = true;
    show(state);
  });
})();
