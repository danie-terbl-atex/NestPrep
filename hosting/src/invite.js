(() => {
  'use strict';

  const ALPHABET = '23456789ABCDEFGHJKMNPQRSTUVWXYZ';
  const status = document.getElementById('invite-status');
  if (status === null) return;

  function show(state) {
    for (const notice of status.querySelectorAll('[data-state]')) {
      notice.hidden = notice.getAttribute('data-state') !== state;
    }
  }

  function codeFromPath(path) {
    const match = /^\/invite\/([^/]+)\/?$/.exec(path);
    if (match === null) return null;
    const code = decodeURIComponent(match[1]).trim().toUpperCase();
    if (code.length !== 8) return null;
    for (const character of code) {
      if (!ALPHABET.includes(character)) return null;
    }
    return code;
  }

  const code = codeFromPath(window.location.pathname);
  if (code === null) {
    show('invalid');
    return;
  }

  document.getElementById('invite-code').textContent = code;
  document.getElementById('invite-open').href = `nestprep://invite/${code}`;
  const copy = document.getElementById('invite-copy');
  copy.addEventListener('click', () => {
    navigator.clipboard
      ?.writeText(code)
      .then(() => {
        copy.textContent = copy.getAttribute('data-copied-label') ?? copy.textContent;
      })
      .catch(() => {});
  });
  show('ready');
})();
