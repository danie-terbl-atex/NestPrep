import { defineBoolean, defineSecret, defineString } from 'firebase-functions/params';

import { configured } from '../shared/configured_value';
import { functionUrlFrom } from '../shared/function_url';
import { HOSTING_REGION } from '../shared/region';

/**
 * Calendar sync's configuration, by name (BE-16, ENG-18). None of it has a
 * value in the repo or the vault; Daniel creates the OAuth apps and sets these
 * (calendar ADR-0003). Until he does, the providers say **not set up yet**
 * rather than failing.
 *
 * - `CALENDAR_GOOGLE_CLIENT_ID`, `CALENDAR_MICROSOFT_CLIENT_ID` — string
 *   params; a client id is not a secret.
 * - `CALENDAR_GOOGLE_CLIENT_SECRET`, `CALENDAR_MICROSOFT_CLIENT_SECRET` —
 *   Secret Manager secrets, bound only to the Functions that exchange or
 *   refresh a token. A bound secret must exist to deploy, so an unconfigured
 *   project holds the value `unset`, which reads as not configured.
 * - `CALENDAR_FUNCTIONS_BASE_URL` — optional; the Hosting origin that rewrites
 *   to the OAuth callback and the feed. Google verifies the redirect's domain,
 *   so production sets it. Empty derives the `cloudfunctions.net` address.
 * - `CALENDAR_GOOGLE_OTHER_CALENDARS` — whether Google is asked for the
 *   account's calendar list and read beyond its primary calendar (calendar
 *   ADR-0007). Off until the consent screen carries the list scope and the
 *   privacy policy says so, because switching it on changes what a member is
 *   asked to agree to.
 */
export const googleClientId = defineString('CALENDAR_GOOGLE_CLIENT_ID', { default: '' });
export const microsoftClientId = defineString('CALENDAR_MICROSOFT_CLIENT_ID', { default: '' });
export const googleClientSecret = defineSecret('CALENDAR_GOOGLE_CLIENT_SECRET');
export const microsoftClientSecret = defineSecret('CALENDAR_MICROSOFT_CLIENT_SECRET');
export const functionsBaseUrl = defineString('CALENDAR_FUNCTIONS_BASE_URL', { default: '' });
export const googleOtherCalendars = defineBoolean('CALENDAR_GOOGLE_OTHER_CALENDARS', {
  default: false,
});

/** What the Functions that talk to a provider's token endpoint must be bound to. */
export const PROVIDER_SECRETS = [googleClientSecret, microsoftClientSecret];

export interface OAuthClient {
  readonly clientId: string;
  readonly clientSecret: string;
}

export interface GoogleClient extends OAuthClient {
  readonly otherCalendars: boolean;
}

/** The OAuth clients that are configured; a provider missing here is not set up. */
export interface OAuthClients {
  google?: GoogleClient;
  microsoft?: OAuthClient;
}

/**
 * The OAuth clients as this instance sees them. [withSecrets] is false in the
 * Functions that are not bound to the secrets — they can still say whether a
 * provider has a client id, which is all "is it set up" needs.
 */
export function oauthClients(withSecrets: boolean): OAuthClients {
  const clients: OAuthClients = {};
  const google = configured(googleClientId.value());
  const microsoft = configured(microsoftClientId.value());
  if (google !== null) {
    clients.google = {
      clientId: google,
      clientSecret: withSecrets ? (configured(googleClientSecret.value()) ?? '') : '',
      otherCalendars: googleOtherCalendars.value(),
    };
  }
  if (microsoft !== null) {
    clients.microsoft = {
      clientId: microsoft,
      clientSecret: withSecrets ? (configured(microsoftClientSecret.value()) ?? '') : '',
    };
  }
  return clients;
}

/**
 * Where a calendar sync Function answers over HTTP: the configured base, or
 * the address Cloud Functions gives it, or the emulator's.
 */
export function functionUrl(name: string): string {
  return functionUrlFrom(configured(functionsBaseUrl.value()), name, HOSTING_REGION);
}
