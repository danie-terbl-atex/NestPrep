import { FieldValue } from 'firebase-admin/firestore';
import { onCall } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';

import { db } from '../shared/firestore';
import { householdRef, memberRef, userRef } from './documents';
import { parseInput, requireUid } from './parse_input';
import { createHouseholdInput } from './schemas';

/**
 * Creates a household with its creator already an admin and already claimed, so
 * every household has an admin from birth — the same shape a redeem produces
 * (household ADR-0002). One transaction: the household, the member profile, the
 * membership map and the account's household list move together or not at all
 * (BE-07).
 */
export const createHousehold = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const input = parseInput(createHouseholdInput, request.data);
  const store = db();

  const household = householdRef(store, store.collection('households').doc().id);
  const member = memberRef(store, household.id, household.collection('members').doc().id);

  // Nothing is read, so this is a batch rather than a transaction: the same
  // all-or-nothing commit without a read set (BE-07).
  const batch = store.batch();
  batch.set(household, {
    name: input.name,
    timeZone: input.timeZone,
    members: { [uid]: 'admin' },
    profiles: { [uid]: member.id },
    // The app shows its admin the invite step until they finish or skip it:
    // inviting a second adult is part of setting up (household ADR-0003).
    pendingSetupStep: 'invitePeople',
    createdBy: uid,
    createdAt: FieldValue.serverTimestamp(),
  });
  batch.set(member, {
    displayName: input.adminDisplayName,
    color: input.adminColor,
    role: 'admin',
    claimedBy: uid,
    createdAt: FieldValue.serverTimestamp(),
  });
  batch.set(
    userRef(store, uid),
    {
      householdIds: FieldValue.arrayUnion(household.id),
      activeHouseholdId: household.id,
    },
    { merge: true },
  );
  await batch.commit();

  logger.info('household created', { householdId: household.id });
  return { householdId: household.id, memberId: member.id };
});
