import { FieldValue, type Firestore } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';

import { MAX_PIN_ATTEMPTS, attemptsLeft } from './share_policy';
import { shareRef, tokenRef } from './share_refs';
import { storedToken } from './share_schemas';
import { isPinShape, pinMatches, type PinHash } from './share_secrets';
import type { LiveShare } from './share_lookup';

export type PinCheck =
  | { readonly kind: 'right'; readonly pin: PinHash }
  | { readonly kind: 'wrong'; readonly attemptsLeft: number }
  | { readonly kind: 'locked' };

/**
 * One PIN attempt against a link (documents ADR-0006). The count is read and
 * written in one transaction, so two guesses at once cannot both be the
 * fourth; the fifth wrong one marks the link `locked` for good and deletes
 * nothing — the family sees in the app that it was locked.
 *
 * A right PIN does not reset the count: a link somebody has been guessing at
 * stays closer to locking, which is the safe direction.
 */
export async function checkPin(store: Firestore, live: LiveShare, pin: string): Promise<PinCheck> {
  return store.runTransaction(async (transaction) => {
    const secrets = storedToken.safeParse(
      (await transaction.get(tokenRef(store, live.tokenHash))).data(),
    );
    if (!secrets.success) return { kind: 'locked' } as const;
    const { pinHash, pinSalt, failedPinAttempts } = secrets.data;
    if (pinHash === null || pinSalt === null) return { kind: 'locked' } as const;
    if (failedPinAttempts >= MAX_PIN_ATTEMPTS) return { kind: 'locked' } as const;
    // Letters or an empty box are not a guess at a number, so they cost
    // nothing; every well-formed wrong PIN does.
    if (!isPinShape(pin)) {
      return { kind: 'wrong', attemptsLeft: attemptsLeft(failedPinAttempts) } as const;
    }

    if (pinMatches(pin, { pinHash, pinSalt })) {
      return { kind: 'right', pin: { pinHash, pinSalt } } as const;
    }
    const failed = failedPinAttempts + 1;
    transaction.update(tokenRef(store, live.tokenHash), { failedPinAttempts: failed });
    if (failed < MAX_PIN_ATTEMPTS) return { kind: 'wrong', attemptsLeft: attemptsLeft(failed) };

    transaction.update(shareRef(store, live.address.householdId, live.shareId), {
      status: 'locked',
      lockedAt: FieldValue.serverTimestamp(),
    });
    logger.warn('document share locked after wrong PINs', {
      householdId: live.address.householdId,
      shareId: live.shareId,
    });
    return { kind: 'locked' } as const;
  });
}
