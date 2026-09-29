import { FieldPath, type Firestore } from 'firebase-admin/firestore';

import { removeCalendarConnection } from '../calendar_sync/remove_connection';
import { CALENDAR_CONNECTIONS, PROVIDERS, type Provider } from '../calendar_sync/sync_documents';
import { VAULT_OPENINGS, grantRef, vaultRef } from '../documents/vault_refs';
import { pushAccountClaims } from '../household/access_claim';
import { MEMBERS, householdRef, memberRef } from '../household/documents';
import { detachMember, findClaimedMember, recordClaim } from '../household/membership';
import type { ObjectStore } from '../shared/storage';
import type { HouseholdPlan } from './deletion_plan';
import { refuseAccountData } from './errors';
import { personalRefs, vaultObjectPrefix } from './personal_refs';

/** Profiles whose vaults might hold a grant to the leaving account. */
const MEMBER_LIMIT = 100;

/** Rows removed per page when clearing what the account left behind. */
const PAGE = 400;

/**
 * An account leaves a household that goes on without it (accounts ADR-0006):
 * a hand-over first when it was the last admin, then the same detachment
 * leaving does, and the person's own details erased — their profile's
 * details, medication, position and vault, the grants they held to other
 * vaults, and the calendars they connected.
 *
 * The membership part is one transaction (BE-07). What follows it — the vault's
 * rows and bytes, calendar credentials — is idempotent and keyed by ids that
 * survive, so a retried deletion finishes what an interrupted one started.
 */
export async function leaveErasing(
  store: Firestore,
  objects: ObjectStore,
  plan: { uid: string; household: HouseholdPlan },
): Promise<void> {
  const { uid, household } = plan;
  const { householdId, outcome } = household;
  const memberId = await store.runTransaction(async (transaction) => {
    const members = await transaction.get(
      householdRef(store, householdId).collection(MEMBERS).limit(MEMBER_LIMIT),
    );
    const claimed = await findClaimedMember(transaction, store, householdId, uid);
    if (outcome.kind === 'handOver') {
      const successor = members.docs.find((doc) => doc.id === outcome.toMemberId);
      if (successor?.get('claimedBy') !== outcome.toUid)
        throw refuseAccountData('deletionPlanChanged');
      transaction.update(memberRef(store, householdId, outcome.toMemberId), {
        role: 'admin',
        access: null,
      });
      recordClaim(transaction, store, {
        householdId,
        uid: outcome.toUid,
        memberId: outcome.toMemberId,
        role: 'admin',
        access: null,
      });
    }
    detachMember(transaction, store, { householdId, uid, claimedMember: claimed });
    for (const member of members.docs) {
      transaction.delete(grantRef(store, householdId, member.id, uid));
    }
    if (claimed === null) return null;
    // The profile stays, unclaimed, so the household's records still read;
    // the one thing on it that is the person's own and not the household's
    // naming of them is their birthday (birthdays ADR-0001).
    transaction.update(claimed, { birthday: null });
    for (const detail of personalRefs(store, householdId, claimed.id)) {
      transaction.delete(detail);
    }
    return claimed.id;
  });

  if (memberId !== null) {
    await store.recursiveDelete(vaultRef(store, householdId, memberId));
    await objects.deletePrefix(vaultObjectPrefix(householdId, memberId));
  }
  await deleteOpeningTickets(store, householdId, uid);
  await removeOwnedCalendars(store, householdId, uid);
  if (outcome.kind === 'handOver') await pushAccountClaims(store, outcome.toUid);
}

/** The short-lived tickets `openVaultDocument` wrote for this account, keyed `uid_documentId`. */
async function deleteOpeningTickets(
  store: Firestore,
  householdId: string,
  uid: string,
): Promise<void> {
  const tickets = await householdRef(store, householdId)
    .collection(VAULT_OPENINGS)
    .where(FieldPath.documentId(), '>=', `${uid}_`)
    .where(FieldPath.documentId(), '<', `${uid}_`)
    .limit(PAGE)
    .get();
  if (tickets.empty) return;
  const batch = store.batch();
  for (const ticket of tickets.docs) batch.delete(ticket.ref);
  await batch.commit();
}

/** A connected calendar is its owner's credential; it goes with them (calendar ADR-0003). */
export async function removeOwnedCalendars(
  store: Firestore,
  householdId: string,
  uid: string | null,
): Promise<void> {
  const collection = householdRef(store, householdId).collection(CALENDAR_CONNECTIONS);
  const owned = await (uid === null ? collection : collection.where('ownerUid', '==', uid))
    .limit(PAGE)
    .get();
  for (const connection of owned.docs) {
    const provider: unknown = connection.get('provider');
    await removeCalendarConnection(store, {
      householdId,
      connectionId: connection.id,
      provider: isProvider(provider) ? provider : 'ics',
    });
  }
}

function isProvider(value: unknown): value is Provider {
  return PROVIDERS.some((provider) => provider === value);
}
