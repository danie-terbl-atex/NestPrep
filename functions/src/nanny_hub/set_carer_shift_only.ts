import { FieldValue } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { onCall } from 'firebase-functions/v2/https';
import { z } from 'zod';

import { householdRef, memberRef } from '../household/documents';
import { parseInput, requireUid } from '../household/parse_input';
import { db } from '../shared/firestore';
import { refuseNanny, type NannyRefusal } from './errors';
import { setCarerShiftOnlyInput } from './schemas';

const storedHousehold = z.object({
  members: z.record(z.string(), z.string()),
});

const storedMember = z.object({ role: z.string() });

/**
 * Whether [uid] may mark the member whose stored profile is [memberData]
 * shift-only: the refusal when not, null when so. Pure over the stored
 * documents, so every branch is tested without an emulator. The same person
 * who chooses a carer's grant chooses this — an admin (household ADR-0003).
 */
export function shiftOnlyRefusal(
  householdData: unknown,
  uid: string,
  memberData: unknown,
): NannyRefusal | null {
  const household = storedHousehold.safeParse(householdData);
  if (!household.success) return 'notAMember';
  const role = household.data.members[uid];
  if (role === undefined) return 'notAMember';
  if (role !== 'admin') return 'notAnAdmin';
  const member = storedMember.safeParse(memberData);
  if (!member.success) return 'memberNotFound';
  if (member.data.role !== 'carer') return 'notACarer';
  return null;
}

/**
 * Marks a carer shift-only, or lifts it (nanny-hub ADR-0006): a shift-only
 * carer sees the household only from 15 minutes before a shift a parent
 * booked for them to 15 minutes after it ends.
 *
 * A Function because the mark lives in the household document, which every
 * rule already reads — so asking it costs nothing on every request — and the
 * household document is written only by Functions (household ADR-0001). The
 * key is the member id, so a carer can be marked before they claim their
 * profile.
 */
export const setCarerShiftOnly = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const input = parseInput(setCarerShiftOnlyInput, request.data);
  const store = db();

  await store.runTransaction(async (transaction) => {
    const household = await transaction.get(householdRef(store, input.householdId));
    const member = await transaction.get(memberRef(store, input.householdId, input.memberId));
    const refusal = shiftOnlyRefusal(
      household.exists ? household.data() : undefined,
      uid,
      member.exists ? member.data() : undefined,
    );
    if (refusal !== null) throw refuseNanny(refusal);

    transaction.update(householdRef(store, input.householdId), {
      [`shiftOnly.${input.memberId}`]: input.shiftOnly ? true : FieldValue.delete(),
    });
  });

  logger.info('carer shift-only changed', {
    householdId: input.householdId,
    shiftOnly: input.shiftOnly,
  });
  return { householdId: input.householdId, memberId: input.memberId, shiftOnly: input.shiftOnly };
});
