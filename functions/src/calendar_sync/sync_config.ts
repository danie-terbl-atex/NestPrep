import { defineSecret, defineString } from 'firebase-functions/params';

import { FUNCTIONS_REGION } from '../shared/region';
import type { OAuthProvider } from './sync_documents';

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
 * - `CALENDAR_FUNCTIONS_BASE_URL` — optional; where the OAuth callback and the
 *   feed are reached. Empty derives the default `cloudfunctions.net` address.
 */
export const googleClientId = defineString('CALENDAR_GOOGLE_CLIENT_ID', { default: '' });
export const microsoftClientId = defineString('CALENDAR_MICROSOFT_CLIENT_ID', { default: '' });
export const googleClientSecret = defineSecret('CALENDAR_GOOGLE_CLIENT_SECRET');
export const microsoftClientSecret = defineSecret('CALENDAR_MICROSOFT_CLIENT_SECRET');
export const functionsBaseUrl = defineString('CALENDAR_FUNCTIONS_BASE_URL', { default: '' });

/** What the Functions that talk to a provider's token endpoint must be bound to. */
export const PROVIDER_SECRETS = [googleClientSecret, microsoftClientSecret];

export interface OAuthClient {
  readonly clientId: string;
  readonly clientSecret: string;
}

/** The OAuth clients that are configured; a provider missing here is not set up. */
export type OAuthClients = Partial<Record<OAuthProvider, OAuthClient>>;

/** Reads a value, treating empty and the deploy placeholder as absent. */
export function configured(value: string): string | null {
  const trimmed = value.trim();
  return trimmed === '' || trimmed === 'unset' ? null : trimmed;
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
 * Where a Function of this codebase answers over HTTP: the configured base, or
 * the address Cloud Functions gives it, or the emulator's.
 */
export function functionUrl(name: string): string {
  const base = configured(functionsBaseUrl.value());
  if (base !== null) return `${base.replace(/\/+$/, '')}/${name}`;
  const project = process.env['GCLOUD_PROJECT'] ?? '';
  if (process.env['FUNCTIONS_EMULATOR'] === 'true') {
    const host = process.env['FUNCTIONS_EMULATOR_HOST'] ?? '127.0.0.1:5001';
    return `http://${host}/${project}/${FUNCTIONS_REGION}/${name}`;
  }
  return `https://${FUNCTIONS_REGION}-${project}.cloudfunctions.net/${name}`;
}
