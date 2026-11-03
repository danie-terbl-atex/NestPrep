// The consent page an assistant sends a member to (assistants ADR-0002). It
// asks `/oauth/consent/describe` who is asking, signs the member in with
// Firebase — always afresh, nothing kept — lists the households where they are
// family, and sends their choice to `/oauth/consent/decide`, which answers
// with where to send the browser. The words for every state are in the page;
// this file only chooses which to show. Firebase's web configuration is
// `/assets/connect-config.json`, built from `hosting/src/connect-config.json`.
(() => {
  'use strict';

  const requestId = new URLSearchParams(location.search).get('request') ?? '';
  const status = document.getElementById('connect-status');
  const asking = document.getElementById('connect-asking');
  const signInPanel = document.getElementById('connect-sign-in');
  const passwordForm = document.getElementById('connect-password');
  const chooseForm = document.getElementById('connect-choose');
  const householdPicker = document.getElementById('connect-household');
  if (status === null || signInPanel === null || chooseForm === null) return;

  let auth = null;
  let idToken = null;
  let busy = false;

  function show(state) {
    for (const notice of status.querySelectorAll('[data-state]')) {
      notice.hidden = notice.getAttribute('data-state') !== state;
    }
    if (state !== null && state !== 'loading') status.focus();
  }

  function showStep(step) {
    signInPanel.hidden = step !== 'signIn';
    chooseForm.hidden = step !== 'choose';
  }

  async function consent(action, body) {
    if (!navigator.onLine) return { ok: false, error: 'offline' };
    try {
      const response = await fetch(`/oauth/consent/${action}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ requestId, ...body }),
        credentials: 'same-origin',
      });
      const answer = await response.json().catch(() => ({}));
      if (response.ok) return { ok: true, answer };
      const known = status.querySelector(`[data-state="${answer.error}"]`) !== null;
      return { ok: false, error: known ? answer.error : 'unavailable' };
    } catch {
      return { ok: false, error: navigator.onLine ? 'unavailable' : 'offline' };
    }
  }

  async function firebaseAuth() {
    const response = await fetch('/assets/connect-config.json', { credentials: 'omit' });
    const config = await response.json();
    if (typeof config.apiKey !== 'string' || config.apiKey === '' || window.firebase === undefined) {
      return null;
    }
    const app = window.firebase.initializeApp(config, 'connect');
    const instance = app.auth();
    await instance.setPersistence(window.firebase.auth.Auth.Persistence.NONE);
    await instance.signOut();
    return instance;
  }

  async function signedIn(credential) {
    idToken = await credential.user.getIdToken();
    const result = await consent('households', { idToken });
    if (!result.ok) {
      await signOut(result.error);
      return;
    }
    const households = result.answer.households;
    if (households.length === 0) {
      await signOut('noHouseholds');
      return;
    }
    householdPicker.replaceChildren(
      ...households.map((household) => {
        const option = document.createElement('option');
        option.value = household.id;
        option.textContent = household.name;
        return option;
      }),
    );
    show(null);
    showStep('choose');
  }

  async function signOut(state) {
    idToken = null;
    if (auth !== null) await auth.signOut();
    showStep('signIn');
    show(state);
  }

  async function attempt(work) {
    if (busy) return;
    busy = true;
    try {
      await work();
    } catch {
      await signOut('signInRequired');
    } finally {
      busy = false;
    }
  }

  async function decide(body) {
    const result = await consent('decide', body);
    if (!result.ok) {
      if (result.error === 'staleSignIn' || result.error === 'signInRequired') {
        await signOut(result.error);
      } else {
        show(result.error);
      }
      return;
    }
    show('sending');
    showStep(null);
    location.assign(result.answer.redirect);
  }

  document.getElementById('connect-google').addEventListener('click', () => {
    attempt(async () => {
      const provider = new window.firebase.auth.GoogleAuthProvider();
      provider.setCustomParameters({ prompt: 'select_account' });
      await signedIn(await auth.signInWithPopup(provider));
    });
  });

  passwordForm.addEventListener('submit', (event) => {
    event.preventDefault();
    if (!passwordForm.reportValidity()) return;
    const email = passwordForm.elements.namedItem('email').value.trim();
    const password = passwordForm.elements.namedItem('password').value;
    attempt(async () => {
      await signedIn(await auth.signInWithEmailAndPassword(email, password));
    });
  });

  chooseForm.addEventListener('submit', (event) => {
    event.preventDefault();
    const scopes = [...chooseForm.querySelectorAll('[data-scope]:not([hidden]) input:checked')].map(
      (input) => input.value,
    );
    if (scopes.length === 0) {
      show('noScopes');
      return;
    }
    attempt(() =>
      decide({ decision: 'allow', idToken, householdId: householdPicker.value, scopes }),
    );
  });

  for (const button of document.querySelectorAll('[data-deny]')) {
    button.addEventListener('click', () => {
      attempt(() => decide({ decision: 'deny' }));
    });
  }

  (async () => {
    const described = await consent('describe', {});
    if (!described.ok) {
      show(described.error);
      return;
    }
    const { clientName, host, scopes } = described.answer;
    document.getElementById('connect-client').textContent = clientName;
    document.getElementById('connect-host').textContent = host;
    for (const row of chooseForm.querySelectorAll('[data-scope]')) {
      row.hidden = !scopes.includes(row.getAttribute('data-scope'));
    }
    asking.hidden = false;
    try {
      auth = await firebaseAuth();
    } catch {
      auth = null;
    }
    if (auth === null) {
      show('notSetUp');
      return;
    }
    show(null);
    showStep('signIn');
  })();
})();
