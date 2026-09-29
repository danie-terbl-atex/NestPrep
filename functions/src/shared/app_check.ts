/**
 * Whether every callable refuses a request without a valid App Check token
 * (foundation's App Check ADR; accounts ADR-0006 for the security pass).
 *
 * **Off until Daniel flips it**, deliberately: the app sends App Check tokens
 * from the release that adds `firebase_app_check`, but every install older than
 * that sends none, and a debug build on a device nobody registered a debug
 * token for sends an invalid one. Turning this on before the console's App
 * Check metrics show nearly every request verified locks those people out with
 * nothing on their screen but "try again".
 *
 * Flipping it is this one line and a deploy. It reaches callables only — the
 * two HTTP endpoints (`calendarFeed`, `requestAccountDeletion`) and the store
 * webhooks are called by calendars, browsers and Apple, which hold no App
 * Check token; they are protected by their own tokens, signatures and the
 * rate limits instead. Firestore, Storage and Auth are enforced separately, in
 * the console.
 */
export const APP_CHECK_ENFORCED = false;
