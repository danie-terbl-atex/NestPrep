import type { Firestore, Transaction } from 'firebase-admin/firestore';
import { z } from 'zod';

import { householdRef, memberRef } from '../household/documents';
import { COPARENT_LINKS } from './coparent_refs';
import { refuseCoParent } from './errors';

/**
 * The kid profile on each side of a link (household ADR-0004). Each home keeps
 * its own profile for the child; a link only says they are the same child, and
 * a profile is in at most one open link.
 */

const kidProfile = z.object({ displayName: z.string().min(1), role: z.literal('kid') });

/** The child's display name in this household, or the refusal that says there is no such kid. */
export async function readKidProfile(
  transaction: Transaction,
  store: Firestore,
  householdId: string,
  memberId: string,
): Promise<string> {
  const snapshot = await transaction.get(memberRef(store, householdId, memberId));
  const profile = kidProfile.safeParse(snapshot.data());
  if (!snapshot.exists || !profile.success) throw refuseCoParent('childNotFound');
  return profile.data.displayName;
}

/**
 * What the other home is told the child is called: the first word of the name
 * this home wrote, and nothing after it — a surname is this household's, not
 * the link's.
 */
export function sharedChildName(displayName: string): string {
  return displayName.trim().split(/\s+/)[0] ?? displayName.trim();
}

const OPEN = new Set(['pending', 'active']);

/** Whether this kid profile is already in a pending or active link. */
export async function isAlreadyLinked(
  transaction: Transaction,
  store: Firestore,
  householdId: string,
  memberId: string,
): Promise<boolean> {
  const mirrors = await transaction.get(
    householdRef(store, householdId)
      .collection(COPARENT_LINKS)
      .where('childMemberId', '==', memberId)
      .limit(10),
  );
  return mirrors.docs.some((mirror) => OPEN.has(String(mirror.get('status'))));
}
