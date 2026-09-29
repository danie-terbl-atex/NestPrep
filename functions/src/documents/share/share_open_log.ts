import { FieldValue, type Firestore } from 'firebase-admin/firestore';

import { viewsOf } from '../vault_refs';
import { shareRef } from './share_refs';
import type { LiveShare } from './share_lookup';

/** What the vault log calls somebody who opened a document through a link. */
export const SHARE_LINK_VIEWER_ROLE = 'shareLink';

/**
 * Records one open of a shared document **before** its first byte is sent
 * (documents ADR-0003, ADR-0006): the link's count and last-opened time, and —
 * for a vault document — a line in that vault's view log, so a vault's bytes
 * still never leave without a log line. One batch: both or neither.
 */
export async function recordShareOpen(store: Firestore, live: LiveShare): Promise<void> {
  const { householdId, ownerMemberId, documentId } = live.address;
  const batch = store.batch();
  batch.update(shareRef(store, householdId, live.shareId), {
    openCount: FieldValue.increment(1),
    lastOpenedAt: FieldValue.serverTimestamp(),
  });
  if (live.address.scope === 'vault' && ownerMemberId !== null) {
    batch.create(viewsOf(store, householdId, ownerMemberId).doc(), {
      documentId,
      documentName: live.documentName,
      viewerMemberId: null,
      viewerRole: SHARE_LINK_VIEWER_ROLE,
      shareId: live.shareId,
      viewedAt: FieldValue.serverTimestamp(),
    });
  }
  await batch.commit();
}
