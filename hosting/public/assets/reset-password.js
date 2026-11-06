// The page a password reset email opens (accounts ADR-0012). The email's link
// carries Firebase's one-time `oobCode`; this checks it, shows which address it
// is for, and sets the new password with the Firebase web SDK Hosting serves.
// The words for every state are in the page; this file only chooses which.
(() => {
  'use strict';

  const MIN_LENGTH = 8;
  const oobCode = new URLSearchParams(location.search).get('oobCode') ?? '';
  const status = document.getElementById('reset-status');
  const form = document.getElementById('reset-form');
  const emailLabel = document.getElementById('reset-email');
  if (status === null || form === null || emailLabel === null) return;

  let auth = null;
  let busy = false;

  function show(state) {
    for (const notice of status.querySelectorAll('[data-state]')) {
      notice.hidden = notice.getAttribute('data-state') !== state;
    }
    if (state !== null && state !== 'loading') status.focus();
  }

  function stateFor(error) {
    if (!navigator.onLine) return 'offline';
    switch (error?.code) {
      case 'auth/expired-action-code':
      case 'auth/invalid-action-code':
      case 'auth/user-disabled':
      case 'auth/user-not-found':
        return 'expired';
      case 'auth/weak-password':
        return 'weak';
      case 'auth/too-many-requests':
        return 'tooMany';
      case 'auth/network-request-failed':
        return 'offline';
      default:
        return 'unavailable';
    }
  }

  async function firebaseAuth() {
    const response = await fetch('/assets/connect-config.json', { credentials: 'omit' });
    const config = await response.json();
    if (typeof config.apiKey !== 'string' || config.apiKey === '' || window.firebase === undefined) {
      return null;
    }
    return window.firebase.initializeApp(config, 'reset-password').auth();
  }

  form.addEventListener('submit', async (event) => {
    event.preventDefault();
    if (busy || auth === null) return;
    const password = form.elements.namedItem('password').value;
    const again = form.elements.namedItem('again').value;
    if (password.length < MIN_LENGTH) {
      show('weak');
      return;
    }
    if (password !== again) {
      show('mismatch');
      return;
    }
    busy = true;
    try {
      await auth.confirmPasswordReset(oobCode, password);
      form.hidden = true;
      show('done');
    } catch (error) {
      const state = stateFor(error);
      if (state === 'expired') form.hidden = true;
      show(state);
    } finally {
      busy = false;
    }
  });

  (async () => {
    if (oobCode === '') {
      show('expired');
      return;
    }
    try {
      auth = await firebaseAuth();
      if (auth === null) {
        show('notSetUp');
        return;
      }
      emailLabel.textContent = await auth.verifyPasswordResetCode(oobCode);
      show(null);
      form.hidden = false;
      form.elements.namedItem('password').focus();
    } catch (error) {
      show(stateFor(error));
    }
  })();
})();
