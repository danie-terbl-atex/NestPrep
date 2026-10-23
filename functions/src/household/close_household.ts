import { FieldValue } from 'firebase-admin/firestore';
import { onCall } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';

import { kidAuthAccounts } from '../accounts/kid_auth_accounts';
import { ERASURE_OPTIONS } from '../account_data/account_data_options';
import { planHousehold } from '../account_data/deletion_plan';
import { endHousehold } from '../account_data/end_household';
import { db } from '../shared/firestore';
import { objectStore } from '../shared/storage';
import { pushAccountClaims } from './access_claim';
import { householdRef, userRef } from './documents';
import { refuse } from './errors';
import { parseInput, requireUid } from './parse_input';
import { CLOSE_CONFIRMATION, closeHouseholdInput } from './schemas';

/**
 * Closes a household for good (household ADR-0007): its last adult, once
 * everybody else who could run it has gone, ends it with everything in it —
 * the same ending deleting their account would give it (accounts ADR-0006) —
 * and keeps their own account.
 *
 * Only the admin, and only when no other family adult has joined: with one
 * there, the household has somebody to hand it to, and closing would take it
 * from them. The outcome is read on the server, never taken from the client.
 *
 * Every step is safe to repeat. A retry after the household itself has gone
 * finds nothing to end and only takes it off the caller's account.
 */
export const closeHousehold = onCall(ERASURE_OPTIONS, async (request) => {
  const uid = requireUid(request.auth);
  const input = parseInput(closeHouseholdInput, request.data);
  if (input.confirmation !== CLOSE_CONFIRMATION) throw refuse('closeNotConfirmed');
  const store = db();
  const { householdId } = input;

  const plan = await planHousehold(store, uid, householdId, new Date());
  if (plan === null) {
    if ((await householdRef(store, householdId).get()).exists) throw refuse('notAMember');
  } else {
    if (plan.role !== 'admin') throw refuse('notAnAdmin');
    if (plan.outcome.kind !== 'end') throw refuse('otherAdultsRemain');
    await endHousehold(
      { store, objects: objectStore(), kidAccounts: kidAuthAccounts() },
      uid,
      householdId,
    );
  }

  const batch = store.batch();
  batch.set(
    userRef(store, uid),
    { householdIds: FieldValue.arrayRemove(householdId), activeHouseholdId: null },
    { merge: true },
  );
  await batch.commit();
  await pushAccountClaims(store, uid);

  logger.info('household closed', { householdId, ended: plan !== null });
  return { householdId };
});
