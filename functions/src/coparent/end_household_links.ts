import { FieldValue, type Firestore } from 'firebase-admin/firestore';
import { z } from 'zod';

import { householdRef } from '../household/documents';
import {
  COPARENT_INVITES,
  COPARENT_LINKS,
  REQUESTS,
  mirrorRef,
  authorityRef,
} from './coparent_refs';
import { SIDES } from './schedule_schema';

/** The part of the authority this needs: which two homes, and whether it is still live. */
const linkShape = z.object({
  householdIds: z.object({ a: z.string().min(1), b: z.string().min(1) }),
  status: z.string(),
});

/** Links one household can hold — one per child, far past any family. */
const LINK_LIMIT = 50;

/**
 * Ends every co-parenting link a household holds, because the household is
 * ending (accounts ADR-0006, household ADR-0007). The other home is told the
 * way `endCoParentLink` tells it — the authority and its mirror read `ended`,
 * its unanswered requests close — and keeps what was already shared, as a
 * read-only record (household ADR-0004). The ending household's own mirrors
 * go with its tree, so only the other side is written here.
 *
 * Codes this household made and nobody has used are deleted, so none can
 * link a child to a household that is gone. Safe to run again.
 */
export async function endHouseholdLinks(store: Firestore, householdId: string): Promise<void> {
  const mirrors = await householdRef(store, householdId)
    .collection(COPARENT_LINKS)
    .limit(LINK_LIMIT)
    .get();
  for (const mirror of mirrors.docs) {
    await endFromOneSide(store, householdId, mirror.id);
  }

  const codes = await store
    .collection(COPARENT_INVITES)
    .where('householdId', '==', householdId)
    .limit(LINK_LIMIT)
    .get();
  if (codes.empty) return;
  const batch = store.batch();
  for (const code of codes.docs) batch.delete(code.ref);
  await batch.commit();
}

async function endFromOneSide(
  store: Firestore,
  householdId: string,
  linkId: string,
): Promise<void> {
  await store.runTransaction(async (transaction) => {
    const authority = await transaction.get(authorityRef(store, linkId));
    const link = linkShape.safeParse(authority.data());
    if (!authority.exists || !link.success) return;
    const { householdIds: pair, status } = link.data;
    if (status !== 'active' && status !== 'pending') return;
    const ownSide = SIDES.find((side) => pair[side] === householdId);
    if (ownSide === undefined) return;
    const otherHousehold = pair[ownSide === 'a' ? 'b' : 'a'];
    const otherMirror = mirrorRef(store, otherHousehold, linkId);
    const [mirror, waiting] = await Promise.all([
      transaction.get(otherMirror),
      transaction.get(
        otherMirror.collection(REQUESTS).where('status', '==', 'pending').limit(LINK_LIMIT),
      ),
    ]);

    const now = FieldValue.serverTimestamp();
    transaction.update(authority.ref, { status: 'ended', awaitingSide: null, updatedAt: now });
    if (!mirror.exists) return;
    transaction.update(otherMirror, {
      status: 'ended',
      awaitingSide: null,
      endedBySide: ownSide,
      updatedAt: now,
    });
    for (const pending of waiting.docs) {
      transaction.update(pending.ref, { status: 'closed', answeredAt: now });
    }
  });
}
