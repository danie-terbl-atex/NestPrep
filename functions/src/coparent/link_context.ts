import type {
  DocumentData,
  DocumentReference,
  Firestore,
  Transaction,
} from 'firebase-admin/firestore';
import { z } from 'zod';

import { refuseCoParent } from './errors';
import { authorityRef, mirrorRef } from './coparent_refs';
import { SIDES, custodySchedule, side, type Side } from './schedule_schema';

/**
 * One link as a callable sees it: the authority's record of which two
 * households and which status, the side the caller's household is, and that
 * household's own mirror (household ADR-0004). Everything a callable writes
 * goes through `writeBoth`, so the two homes' copies never differ.
 */

export const LINK_STATUSES = ['pending', 'active', 'declined', 'ended'] as const;
export type LinkStatus = (typeof LINK_STATUSES)[number];

const pair = z.object({ a: z.string().min(1), b: z.string().min(1) });

const authorityShape = z.object({
  householdIds: pair,
  childMemberIds: pair,
  status: z.enum(LINK_STATUSES),
  awaitingSide: side.nullable().optional(),
});

const mirrorShape = z.object({
  schedule: custodySchedule,
  overrides: z.record(z.string(), side).optional(),
});

export interface LinkContext {
  readonly linkId: string;
  readonly side: Side;
  readonly otherSide: Side;
  readonly status: LinkStatus;
  readonly awaitingSide: Side | null;
  readonly householdIds: Readonly<Record<Side, string>>;
  readonly overrides: Readonly<Record<string, Side>>;
}

export function otherSideOf(own: Side): Side {
  return own === 'a' ? 'b' : 'a';
}

/**
 * The link, as seen from `householdId`. A link the household is not part of
 * reads exactly like one that does not exist, so a guessed id says nothing.
 */
export async function readLink(
  transaction: Transaction,
  store: Firestore,
  linkId: string,
  householdId: string,
): Promise<LinkContext> {
  const snapshot = await transaction.get(authorityRef(store, linkId));
  const authority = authorityShape.safeParse(snapshot.data());
  if (!snapshot.exists || !authority.success) throw refuseCoParent('linkNotFound');
  const { householdIds } = authority.data;
  const own = SIDES.find((candidate) => householdIds[candidate] === householdId);
  if (own === undefined) throw refuseCoParent('linkNotFound');

  const mirror = mirrorShape.safeParse(
    (await transaction.get(mirrorRef(store, householdId, linkId))).data(),
  );
  if (!mirror.success) throw refuseCoParent('linkNotFound');

  return {
    linkId,
    side: own,
    otherSide: otherSideOf(own),
    status: authority.data.status,
    awaitingSide: authority.data.awaitingSide ?? null,
    householdIds,
    overrides: mirror.data.overrides ?? {},
  };
}

/** Refuses anything but an active link: nothing new crosses until both said yes. */
export function requireActive(link: LinkContext): void {
  if (link.status !== 'active') throw refuseCoParent('linkNotActive');
}

/** The same document under each household's mirror of the link. */
export function bothRefs(
  link: LinkContext,
  refFor: (householdId: string) => DocumentReference,
): DocumentReference[] {
  return SIDES.map((each) => refFor(link.householdIds[each]));
}

/** Stages one update on both mirrors of the link, in the caller's transaction. */
export function updateBothMirrors(
  transaction: Transaction,
  store: Firestore,
  link: LinkContext,
  patch: DocumentData,
): void {
  for (const ref of bothRefs(link, (householdId) => mirrorRef(store, householdId, link.linkId))) {
    transaction.update(ref, patch);
  }
}
