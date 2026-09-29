import { applicationDefault, type Credential } from 'firebase-admin/app';

/**
 * Where a Vertex call's bearer token comes from (foundation ADR-0015).
 *
 * On Cloud Functions that is the runtime service account, through the
 * metadata server — the same identity every other admin call uses, and no key
 * to create, store or rotate (ENG-18). An interface so a test, or a one-off
 * smoke script run with somebody's `gcloud` login, can hand in its own.
 */
export interface AccessTokenSource {
  token(): Promise<string>;
}

let credential: Credential | undefined;

/** Application default credentials; the credential caches until expiry. */
export const applicationDefaultTokens: AccessTokenSource = {
  async token(): Promise<string> {
    credential ??= applicationDefault();
    const { access_token: accessToken } = await credential.getAccessToken();
    return accessToken;
  },
};
