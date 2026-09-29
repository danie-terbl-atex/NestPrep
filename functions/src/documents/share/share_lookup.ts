import type { Firestore } from 'firebase-admin/firestore';
import { z } from 'zod';

import { knownZoneOr } from '../../calendar_sync/zoned_time';
import { shiftRef } from '../../nanny_hub/nanny_refs';
import { readFlag } from '../../shared/feature_flags';
import { stillMayShare } from './share_caller';
import { type ShareVerdict, verdictFor } from './share_policy';
import { shareRef, sharedDocumentRef, tokenRef, type SharedDocumentAddress } from './share_refs';
import { storedShare, storedToken, type StoredShare, type StoredToken } from './share_schemas';
import { hashShareToken, isShareTokenShape } from './share_secrets';

const documentShape = z.object({ name: z.string(), contentType: z.string() });
const shiftShape = z.object({ status: z.string() });

/** Everything the page and the file need to know about one live link. */
export interface LiveShare {
  readonly tokenHash: string;
  readonly shareId: string;
  readonly token: StoredToken;
  readonly share: StoredShare;
  readonly address: SharedDocumentAddress;
  readonly householdName: string;
  readonly timeZone: string;
  readonly documentName: string;
  readonly contentType: string;
}

export type LookedUp =
  | { readonly kind: 'notFound' }
  | { readonly kind: 'refused'; readonly verdict: Exclude<ShareVerdict, 'open'> | 'locked' }
  | { readonly kind: 'live'; readonly live: LiveShare };

/**
 * Resolves a link's token to a live share, or says why not (documents
 * ADR-0006). Every check runs on every request: the share's status and
 * expiry, its shift, the switch, whether its creator could still share it,
 * and whether the document is still there. A token that matches nothing is
 * `notFound`, which says nothing about why.
 */
export async function lookUpShare(store: Firestore, token: string, now: Date): Promise<LookedUp> {
  if (!isShareTokenShape(token)) return { kind: 'notFound' };
  const tokenHash = hashShareToken(token);
  const secrets = storedToken.safeParse((await tokenRef(store, tokenHash).get()).data());
  if (!secrets.success) return { kind: 'notFound' };
  const { householdId, shareId } = secrets.data;
  const share = storedShare.safeParse((await shareRef(store, householdId, shareId).get()).data());
  if (!share.success) return { kind: 'notFound' };
  if (share.data.status === 'locked') return { kind: 'refused', verdict: 'locked' };

  const address: SharedDocumentAddress = {
    householdId,
    scope: share.data.scope,
    ownerMemberId: share.data.ownerMemberId,
    documentId: share.data.documentId,
  };
  const [creator, document, shiftIsOpen, featureIsOn] = await Promise.all([
    stillMayShare(store, address, share.data.createdByUid),
    sharedDocumentRef(store, address).get(),
    shiftStillOpen(store, householdId, share.data.shiftId),
    readFlag(store, 'documentShareLinks'),
  ]);
  const metadata = documentShape.safeParse(document.data());
  const verdict = verdictFor(
    {
      status: share.data.status,
      expiresAt: share.data.expiresAt.toDate(),
      shiftIsOpen,
      featureIsOn,
      creatorMayShare: creator.allowed,
      documentExists: metadata.success,
    },
    now,
  );
  if (verdict !== 'open' || creator.household === null || !metadata.success) {
    return { kind: 'refused', verdict: verdict === 'open' ? 'ended' : verdict };
  }
  return {
    kind: 'live',
    live: {
      tokenHash,
      shareId,
      token: secrets.data,
      share: share.data,
      address,
      householdName: creator.household.name,
      timeZone: knownZoneOr(creator.household.timeZone),
      documentName: metadata.data.name,
      contentType: metadata.data.contentType,
    },
  };
}

async function shiftStillOpen(
  store: Firestore,
  householdId: string,
  shiftId: string | null,
): Promise<boolean> {
  if (shiftId === null) return true;
  const shift = shiftShape.safeParse((await shiftRef(store, householdId, shiftId).get()).data());
  return shift.success && shift.data.status === 'open';
}
