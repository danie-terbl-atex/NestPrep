import type { DocumentReference, Firestore } from 'firebase-admin/firestore';
import { onCall } from 'firebase-functions/v2/https';

import { parseInput } from '../household/parse_input';
import { db } from '../shared/firestore';
import { readLinkedFrame } from './frame_access';
import { type FrameShareKind, frameRef } from './frame_documents';
import { refuseFrame } from './frame_errors';
import {
  FRAME_DEVICE_OPTIONS,
  FRAME_SHARE_WAIT_MS,
  FRAME_SHARE_WAIT_PER_CREDENTIAL,
} from './frame_policy';
import { waitFrameShareInput } from './frame_schemas';
import { type FrameShared, awaitFrameShare, shareQualifies, shared } from './frame_shares';

export type WaitFrameShareResult =
  { status: 'unlinked' } | { status: 'linked'; share: FrameShared | null };

const UNLINKED: WaitFrameShareResult = { status: 'unlinked' };

export const waitFrameShare = onCall(
  { ...FRAME_DEVICE_OPTIONS, timeoutSeconds: 90 },
  async (request): Promise<WaitFrameShareResult> => {
    const { secret, after, accepts } = parseInput(waitFrameShareInput, request.data);
    const store = db();
    const linked = await readLinkedFrame(store, secret, FRAME_SHARE_WAIT_PER_CREDENTIAL);
    if (linked === null) return UNLINKED;
    const { frame } = linked;
    if (!frame.panels.share) throw refuseFrame('sharingOff');
    const ref = frameRef(store, linked.home.id, linked.frameId);
    if (!sameKinds(frame.accepts, accepts)) await recordAccepts(store, ref, accepts);
    if (shareQualifies(frame.share, after, new Date(), accepts)) {
      return { status: 'linked', share: shared(frame.share) };
    }
    return {
      status: 'linked',
      share: await awaitFrameShare(ref, after, FRAME_SHARE_WAIT_MS, accepts),
    };
  },
);

function sameKinds(stored: readonly FrameShareKind[], asked: readonly FrameShareKind[]): boolean {
  return stored.length === asked.length && asked.every((kind) => stored.includes(kind));
}

async function recordAccepts(
  store: Firestore,
  ref: DocumentReference,
  accepts: readonly FrameShareKind[],
): Promise<void> {
  await store.runTransaction(async (transaction) => {
    if ((await transaction.get(ref)).exists) transaction.update(ref, { accepts });
  });
}
