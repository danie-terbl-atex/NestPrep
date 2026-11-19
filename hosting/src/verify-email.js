// The page a welcome email's Confirm button opens (accounts ADR-0015). The
// link carries Firebase's one-time `oobCode`; this applies it with the Firebase
// web SDK Hosting serves. The words for every state are in the page; this file
// only chooses which.
(() => {
  'use strict';

  const oobCode = new URLSearchParams(location.search).get('oobCode') ?? '';
  const status = document.getElementById('verify-status');
  if (status === null) return;

  function show(state) {
    for (const notice of status.querySelectorAll('[data-state]')) {
      notice.hidden = notice.getAttribute('data-state') !== state;
    }
    if (state !== 'loading') status.focus();
  }

  function stateFor(error) {
    if (!navigator.onLine) return 'offline';
    switch (error?.code) {
      case 'auth/expired-action-code':
      case 'auth/invalid-action-code':
      case 'auth/user-disabled':
      case 'auth/user-not-found':
        return 'expired';
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
    return window.firebase.initializeApp(config, 'verify-email').auth();
  }

  (async () => {
    if (oobCode === '') {
      show('expired');
      return;
    }
    try {
      const auth = await firebaseAuth();
      if (auth === null) {
        show('notSetUp');
        return;
      }
      await auth.applyActionCode(oobCode);
      show('done');
    } catch (error) {
      show(stateFor(error));
    }
  })();
})();
