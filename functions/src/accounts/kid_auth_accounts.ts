import { logger } from 'firebase-functions/v2';

import { auth } from '../shared/auth';
import { KID_CLAIM, type KidIdentity } from './kid_identity';

/**
 * The Auth half of a kid device (accounts ADR-0003): the user it signs in as,
 * the claim that says whose profile it is, and the custom token that gets it
 * there. Behind an interface so the rules of the callables are not tied to
 * the Admin SDK (`BE-09`).
 */
export interface KidAuthAccounts {
  /** Creates the device's Auth user with its claim, and mints its sign-in token. */
  open(uid: string, identity: KidIdentity): Promise<string>;

  /**
   * Ends devices' sessions and deletes their users. Called after the household
   * has already stopped trusting them — the `kids` map is what the rules read —
   * so a failure here is logged rather than thrown: the device can already do
   * nothing, and failing the parent's "sign out" over an Auth hiccup would say
   * the opposite of what is true (`ENG-10`: a decision, not a swallowed error).
   */
  close(uids: readonly string[]): Promise<void>;
}

export function kidAuthAccounts(): KidAuthAccounts {
  return {
    async open(uid: string, identity: KidIdentity): Promise<string> {
      await auth().createUser({ uid });
      // On the user record rather than only in the custom token, so every
      // token refreshed after this one still carries it.
      await auth().setCustomUserClaims(uid, { [KID_CLAIM]: identity });
      // Signs with `iam.signBlob` as the runtime service account on Cloud
      // Functions, which needs Service Account Token Creator on itself.
      return auth().createCustomToken(uid);
    },

    async close(uids: readonly string[]): Promise<void> {
      const results = await Promise.allSettled(
        uids.map(async (uid) => {
          await auth().revokeRefreshTokens(uid);
          await auth().deleteUser(uid);
        }),
      );
      const failed = results.filter((result) => result.status === 'rejected').length;
      if (failed > 0) {
        logger.warn('kid device users not fully closed', { failed, total: uids.length });
      }
    },
  };
}
