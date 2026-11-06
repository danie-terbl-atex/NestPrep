import type { DocumentReference, Firestore, Transaction } from 'firebase-admin/firestore';
import { onCall } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';

import { kidAuthAccounts } from '../accounts/kid_auth_accounts';
import { detachKidDevices, readKidDeviceUids } from '../accounts/kid_devices';
import { memberDetailRefs } from '../family_profiles/member_details';
import { forgetWhereTheyWere } from '../live_location/forget_location';
import { db } from '../shared/firestore';
import { INVITES, adminCount, memberRef, readHousehold, roleOf } from './documents';
import { refuse } from './errors';
import { detachMember, readMember } from './membership';
import { parseInput, requireUid } from './parse_input';
import { removeMemberInput } from './schemas';

/**
 * An admin removes a profile from the household. A claimed profile is detached
 * from its account first, which is the same work leaving does — so the account
 * stops seeing the household either way (household ADR-0002). An admin removing
 * themselves is refused: that is leaving, and leaving has the last-admin check.
 *
 * Every kid device signed in as the profile goes with it, in the same
 * transaction, so no tablet is left acting as somebody who is not there
 * (accounts ADR-0003).
 *
 * What the household knew about the person — their family profile and their
 * medication — is deleted with them (family-profiles ADR-0001), and so is
 * where they were (live-location ADR-0004).
 *
 * An invite nobody has used yet goes too, so a link already shared answers
 * "not a NestPrep invite" rather than pointing at a profile that is gone
 * (household ADR-0009).
 */
export const removeMember = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const input = parseInput(removeMemberInput, request.data);
  const store = db();

  const kidDevices = await store.runTransaction(async (transaction) => {
    const household = await readHousehold(transaction, store, input.householdId, () =>
      refuse('householdNotFound'),
    );
    if (roleOf(household, uid) !== 'admin') throw refuse('notAnAdmin');

    const member = await readMember(transaction, store, input.householdId, input.memberId);
    if (member === undefined) throw refuse('memberNotFound');
    if (member.claimedBy === uid) throw refuse('cannotRemoveSelf');
    const devices = await readKidDeviceUids(transaction, store, input.householdId, input.memberId);
    const openInvites = await readOpenInvites(
      transaction,
      store,
      input.householdId,
      input.memberId,
    );

    if (member.claimedBy !== null) {
      if (member.role === 'admin' && adminCount(household) === 1) {
        throw refuse('lastAdmin');
      }
      detachMember(transaction, store, {
        householdId: input.householdId,
        uid: member.claimedBy,
        claimedMember: memberRef(store, input.householdId, input.memberId),
      });
    }
    transaction.delete(memberRef(store, input.householdId, input.memberId));
    // family-profiles: their allergies, medication and the rest go with them.
    for (const detail of memberDetailRefs(store, input.householdId, input.memberId)) {
      transaction.delete(detail);
    }
    detachKidDevices(transaction, store, input.householdId, devices);
    for (const invite of openInvites) transaction.delete(invite);
    return devices;
  });
  await kidAuthAccounts().close(kidDevices);
  await forgetWhereTheyWere(store, input.householdId, input.memberId);

  logger.info('member removed', { householdId: input.householdId });
  return { householdId: input.householdId };
});

async function readOpenInvites(
  transaction: Transaction,
  store: Firestore,
  householdId: string,
  memberId: string,
): Promise<DocumentReference[]> {
  const invites = await transaction.get(
    store
      .collection(INVITES)
      .where('householdId', '==', householdId)
      .where('memberId', '==', memberId),
  );
  return invites.docs
    .filter((invite) => invite.get('redeemedBy') == null)
    .map((invite) => invite.ref);
}
