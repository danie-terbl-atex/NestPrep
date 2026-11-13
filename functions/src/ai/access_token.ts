import { execFile } from 'node:child_process';
import { promisify } from 'node:util';

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

/**
 * A developer's own sign-in, for `live: true` under the emulator (recipes
 * ADR-0008 §11). A separate process, because the Functions emulator wraps this
 * process's HTTP and a token request through it never returns.
 */
export const developerGcloudTokens: AccessTokenSource = {
  async token(): Promise<string> {
    const { stdout } = await promisify(execFile)(
      'gcloud',
      ['auth', 'application-default', 'print-access-token'],
      { timeout: 15_000 },
    );
    return stdout.trim();
  },
};

/** Application default credentials; the credential caches until expiry. */
export const applicationDefaultTokens: AccessTokenSource = {
  async token(): Promise<string> {
    credential ??= applicationDefault();
    const { access_token: accessToken } = await credential.getAccessToken();
    return accessToken;
  },
};
