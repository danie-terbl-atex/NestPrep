import { FieldValue, type DocumentReference, type Firestore } from 'firebase-admin/firestore';
import { onCall } from 'firebase-functions/v2/https';

import { isOccurrence } from '../chore_points/occurrence_check';
import { storedRoutine, storedTask } from '../chore_points/point_documents';
import { completionRef, routineRef, taskRef } from '../chore_points/point_refs';
import { parseInput } from '../household/parse_input';
import { choreOccurrencesOn } from '../notifications/day_occurrences';
import { completionKey } from '../notifications/digest_reads';
import { db } from '../shared/firestore';
import { type LinkedFrame, readLinkedFrame } from './frame_access';
import { parsed } from './frame_documents';
import { refuseFrame } from './frame_errors';
import { FRAME_DEVICE_OPTIONS, FRAME_TICK_PER_CREDENTIAL } from './frame_policy';
import { homeCareRoutineShape, homeCareTickShape, readMembers } from './frame_reads';
import { tickFrameItemInput, type TickFrameItemInput } from './frame_schemas';
import { creditFor, inTickReach, nextTicks } from './frame_ticks';

export type TickFrameItemResult = { status: 'unlinked' } | { status: 'linked'; done: boolean };

const UNLINKED: TickFrameItemResult = { status: 'unlinked' };

/**
 * A linked frame ticks a chore or a routine step off (photo-frames ADR-0007),
 * by writing exactly the document the app would, so stars, the digest and
 * every phone follow without knowing a frame did it. Only what the frame's
 * panels show can be ticked, and only today and the overdue week behind it.
 */
export const tickFrameItem = onCall(
  FRAME_DEVICE_OPTIONS,
  async (request): Promise<TickFrameItemResult> => {
    const input = parseInput(tickFrameItemInput, request.data);
    const store = db();
    const linked = await readLinkedFrame(store, input.secret, FRAME_TICK_PER_CREDENTIAL);
    if (linked === null) return UNLINKED;
    if (!inTickReach(input.date, linked.clock.date)) throw refuseFrame('itemOutOfReach');

    const done =
      input.kind === 'task'
        ? await tickTask(store, linked, input)
        : await tickRoutine(store, linked, input);
    return { status: 'linked', done };
  },
);

async function tickTask(
  store: Firestore,
  { frame, home }: LinkedFrame,
  input: TickFrameItemInput,
): Promise<boolean> {
  const task = parsed(storedTask, (await taskRef(store, home.id, input.id).get()).data());
  if (task === null) throw refuseFrame('itemNotFound');
  const routine =
    task.routineId === null
      ? null
      : parsed(storedRoutine, (await routineRef(store, home.id, task.routineId).get()).data());
  const routines = task.routineId === null || routine === null ? {} : { [task.routineId]: routine };
  const [chore] = choreOccurrencesOn(input.date, [{ id: input.id, task }], routines);
  const helperId = frame.panels.helperMemberId;
  const shown =
    frame.panels.todos || (helperId !== null && chore?.assigneeIds.includes(helperId) === true);
  if (chore === undefined || !shown) throw refuseFrame('itemNotFound');

  const ref = completionRef(store, home.id, completionKey(input.id, input.date));
  if (!input.done) {
    const batch = store.batch();
    batch.delete(ref);
    await batch.commit();
    return false;
  }

  const memberId = await creditedMember(home, chore.assigneeIds, input.by ?? null);
  await store.runTransaction(async (transaction) => {
    if ((await transaction.get(ref)).exists) return;
    transaction.set(ref, {
      taskId: input.id,
      occurrenceDate: input.date,
      completedBy: memberId,
      completedFor: memberId,
      completedAt: FieldValue.serverTimestamp(),
    });
  });
  return true;
}

async function creditedMember(
  home: DocumentReference,
  assigneeIds: readonly string[],
  by: string | null,
): Promise<string> {
  const { names } = await readMembers(home);
  const eligible =
    assigneeIds.length === 0
      ? Object.keys(names)
      : assigneeIds.filter((id) => names[id] !== undefined);
  const memberId = creditFor(eligible, names, by);
  if (memberId === null) throw refuseFrame('whoNeeded');
  return memberId;
}

async function tickRoutine(
  store: Firestore,
  { frame, home }: LinkedFrame,
  input: TickFrameItemInput,
): Promise<boolean> {
  const routine = parsed(
    homeCareRoutineShape,
    (await home.collection('homeCareRoutines').doc(input.id).get()).data(),
  );
  const step = input.step ?? null;
  const itemIds = routine?.items.map((item) => item.id) ?? [];
  if (
    routine === null ||
    routine.helperId !== frame.panels.helperMemberId ||
    !isOccurrence(routine.firstDate, routine.recurrence, input.date) ||
    (step !== null && !itemIds.includes(step))
  ) {
    throw refuseFrame('itemNotFound');
  }

  const ref = home.collection('homeCareRoutineTicks').doc(`${input.id}_${input.date}`);
  return store.runTransaction(async (transaction) => {
    const ticked = parsed(homeCareTickShape, (await transaction.get(ref)).data())?.doneItemIds;
    const doneItemIds = nextTicks(itemIds, ticked ?? [], step, input.done);
    transaction.set(ref, {
      routineId: input.id,
      occurrenceDate: input.date,
      helperId: routine.helperId,
      doneItemIds,
      updatedBy: routine.helperId,
      updatedAt: FieldValue.serverTimestamp(),
    });
    return itemIds.length > 0 && doneItemIds.length === itemIds.length;
  });
}
