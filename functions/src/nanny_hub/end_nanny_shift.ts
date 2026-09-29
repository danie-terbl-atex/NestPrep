import { FieldValue } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { onCall } from 'firebase-functions/v2/https';
import { z } from 'zod';

import { householdRef } from '../household/documents';
import { parseInput, requireUid } from '../household/parse_input';
import { db } from '../shared/firestore';
import { refuseNanny } from './errors';
import { isOffShift } from '../household/shift_window';
import { hubEditorFrom, mayEndShift } from './hub_caller';
import { MOMENTS, checklistRef, entriesOf, shiftRef, summaryRef } from './nanny_refs';
import { endNannyShiftInput } from './schemas';
import { summariseShift } from './shift_summary';

const storedShift = z.object({
  carerMemberId: z.string(),
  status: z.string(),
  startedAt: z.unknown(),
  ticks: z.unknown().optional(),
});

/**
 * Ends a shift and writes what the parents read about it (nanny-hub ADR-0002).
 *
 * A Function rather than a rule for two reasons a rule cannot meet: the
 * summary is a second document written with the end, and it is *derived* from
 * every entry the carer logged — which a rule cannot read, count or sort. The
 * end, the summary and the reads it is made from are one transaction, so an
 * entry logged at the last second is either in the summary or refused by the
 * rules as belonging to an ended shift, never neither (BE-06, BE-07).
 *
 * The summary is born with `delivery.state: 'pending'`. Sending it to the
 * parents' phones is the notifications feature's, which picks up exactly that
 * — the contract is in the nanny-hub overview. The app shows it in the hub at
 * once, so nothing waits on a push that may not exist yet (BE-09).
 */
export const endNannyShift = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const input = parseInput(endNannyShiftInput, request.data);
  const store = db();

  const summary = await store.runTransaction(async (transaction) => {
    const household = await transaction.get(householdRef(store, input.householdId));
    if (!household.exists) throw refuseNanny('notAMember');
    const caller = hubEditorFrom(household.data(), uid);
    // A shift-only carer ends a shift only inside its booked window; family
    // ends it any time (nanny-hub ADR-0006).
    if (await isOffShift(store, input.householdId, household.data(), uid, new Date())) {
      throw refuseNanny('hubNotShared');
    }

    const shiftSnapshot = await transaction.get(shiftRef(store, input.householdId, input.shiftId));
    const shift = storedShift.safeParse(shiftSnapshot.data());
    if (!shiftSnapshot.exists || !shift.success) throw refuseNanny('shiftNotFound');
    if (shift.data.status !== 'open') throw refuseNanny('shiftAlreadyEnded');
    if (!mayEndShift(caller, shift.data.carerMemberId)) throw refuseNanny('notYourShift');

    const entries = await transaction.get(entriesOf(store, input.householdId, input.shiftId));
    const checklists: Record<string, unknown> = {};
    for (const moment of MOMENTS) {
      const checklist = await transaction.get(checklistRef(store, input.householdId, moment));
      if (checklist.exists) checklists[moment] = checklist.data();
    }

    const fields = summariseShift({
      entries: entries.docs.map((entry) => entry.data()),
      ticks: shift.data.ticks,
      checklists,
    });

    transaction.update(shiftRef(store, input.householdId, input.shiftId), {
      status: 'ended',
      endedAt: FieldValue.serverTimestamp(),
      endedBy: caller.memberId,
    });
    transaction.set(summaryRef(store, input.householdId, input.shiftId), {
      ...fields,
      carerMemberId: shift.data.carerMemberId,
      startedAt: shift.data.startedAt,
      endedAt: FieldValue.serverTimestamp(),
      endedBy: caller.memberId,
      closingNote: input.closingNote,
      delivery: { state: 'pending' },
    });
    return fields;
  });

  // Counts and ids only: never a note, which is about a child (ENG-22).
  logger.info('nanny shift ended', {
    householdId: input.householdId,
    shiftId: input.shiftId,
    entryCount: summary.entryCount,
    unreadableCount: summary.unreadableCount,
  });
  return { shiftId: input.shiftId, entryCount: summary.entryCount };
});
