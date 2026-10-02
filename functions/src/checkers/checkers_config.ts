import { defineSecret, defineString } from 'firebase-functions/params';

import { configured } from '../shared/configured_value';

/**
 * Add to Checkers' configuration, by name (BE-16, ENG-18; the Checkers build
 * contract). The values are the Sixty60 Android app's own public client
 * identity — the same for every install, embedded in the app — and live only
 * in the git-ignored `functions/.env.<project>`; the session key lives only in
 * Secret Manager. None of it is in the repo or the vault.
 *
 * - `CHECKERS_API_KEY` — the app's `x-api-key` for the Shoprite identity calls.
 * - `CHECKERS_PROFILE_TOKEN` — the app's bearer for the customer-profile call.
 * - `CHECKERS_APP_VERSION` — the app version string Checkers expects, e.g.
 *   `Android 2.0.114 (…)`; `CHECKERS_APP_VERSION_CODE` is its build number.
 * - `CHECKERS_SESSION_KEY` (secret) — 32 random bytes, base64: the AES-256-GCM
 *   key every stored session and identifier is sealed with.
 */
export const checkersApiKey = defineString('CHECKERS_API_KEY', { default: '' });
export const checkersProfileToken = defineString('CHECKERS_PROFILE_TOKEN', { default: '' });
export const checkersAppVersion = defineString('CHECKERS_APP_VERSION', { default: '' });
export const checkersAppVersionCode = defineString('CHECKERS_APP_VERSION_CODE', { default: '' });
export const checkersSessionKey = defineSecret('CHECKERS_SESSION_KEY');

/** What the callables that seal or open a session are bound to. */
export const CHECKERS_SECRETS = [checkersSessionKey];

/** The Sixty60 app as Checkers knows it — sent on every call, never a person's. */
export interface CheckersAppIdentity {
  readonly apiKey: string;
  readonly profileToken: string;
  readonly appVersion: string;
  readonly appVersionCode: string;
}

/** The configured identity, or null while any part of it is not set. */
export function checkersAppIdentity(): CheckersAppIdentity | null {
  const apiKey = configured(checkersApiKey.value());
  const profileToken = configured(checkersProfileToken.value());
  const appVersion = configured(checkersAppVersion.value());
  const appVersionCode = configured(checkersAppVersionCode.value());
  if (apiKey === null || profileToken === null || appVersion === null || appVersionCode === null) {
    return null;
  }
  return { apiKey, profileToken, appVersion, appVersionCode };
}
