(() => {
  'use strict';

  const ALPHABET = '23456789ABCDEFGHJKMNPQRSTUVWXYZ';
  const status = document.getElementById('frame-status');
  if (status === null) return;

  function show(state) {
    for (const notice of status.querySelectorAll('[data-state]')) {
      notice.hidden = notice.getAttribute('data-state') !== state;
    }
  }

  function codeFromPath(path) {
    const match = /^\/frame\/([^/]+)\/?$/.exec(path);
    if (match === null) return null;
    const code = decodeURIComponent(match[1]).trim().toUpperCase();
    if (code.length !== 6) return null;
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

  document.getElementById('frame-code').textContent = code;
  document.getElementById('frame-open').href = `nestprep://frame/${code}`;
  show('ready');
})();
