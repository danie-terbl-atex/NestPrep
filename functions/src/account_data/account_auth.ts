import { logger } from 'firebase-functions/v2';

import { auth } from '../shared/auth';

/**
 * The Auth half of erasing an account, behind an interface so the erasure is
 * not tied to the Admin SDK (`BE-09`).
 */
export interface AccountAuth {
  /** Ends every session and deletes the user; a user already gone is done. */
  remove(uid: string): Promise<void>;
  /** The uid for an address, for a deletion request made on the web; null when none. */
  uidForEmail(email: string): Promise<string | null>;
  /** What Auth holds about the person, for their export; null when the user is gone. */
  describe(uid: string): Promise<AuthRecord | null>;
}

/** The sign-in facts Firebase Auth keeps, as an export shows them (accounts ADR-0006). */
export interface AuthRecord {
  readonly email: string | null;
  readonly emailVerified: boolean;
  readonly displayName: string | null;
  readonly signInMethods: readonly string[];
  readonly createdAt: string | null;
  readonly lastSignedInAt: string | null;
}

function isNotFound(error: unknown): boolean {
  return (
    typeof error === 'object' &&
    error !== null &&
    'code' in error &&
    error.code === 'auth/user-not-found'
  );
}

export function accountAuth(): AccountAuth {
  return {
    async remove(uid: string): Promise<void> {
      try {
        await auth().revokeRefreshTokens(uid);
        await auth().deleteUser(uid);
      } catch (error: unknown) {
        // A retried erasure meets a user the first attempt already deleted,
        // which is the outcome it wanted (ENG-10: handled, not swallowed).
        if (!isNotFound(error)) throw error;
        logger.info('account user was already gone');
      }
    },
    async describe(uid: string): Promise<AuthRecord | null> {
      try {
        const user = await auth().getUser(uid);
        return {
          email: user.email ?? null,
          emailVerified: user.emailVerified,
          displayName: user.displayName ?? null,
          signInMethods: user.providerData.map((provider) => provider.providerId),
          createdAt: isoOrNull(user.metadata.creationTime),
          lastSignedInAt: isoOrNull(user.metadata.lastSignInTime),
        };
      } catch (error: unknown) {
        if (isNotFound(error)) return null;
        throw error;
      }
    },
    async uidForEmail(email: string): Promise<string | null> {
      try {
        return (await auth().getUserByEmail(email)).uid;
      } catch (error: unknown) {
        if (isNotFound(error)) return null;
        throw error;
      }
    },
  };
}

/** Auth reports times as HTTP dates; an export carries ISO-8601 (`ENG-21`). */
function isoOrNull(value: string | undefined): string | null {
  if (value === undefined || value === '') return null;
  const parsed = new Date(value);
  return Number.isNaN(parsed.getTime()) ? null : parsed.toISOString();
}
