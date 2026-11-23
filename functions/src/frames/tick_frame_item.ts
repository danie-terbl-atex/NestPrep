import { FieldValue, type DocumentReference, type Firestore } from 'firebase-admin/firestore';
import { onCall } from 'firebase-functions/v2/https';

import { isOccurrence } from '../chore_points/occurrence_check';
import { storedRoutine, storedTask } from '../chore_points/point_documents';
import { completionRef, routineRef, taskRef } from '../chore_points/point_refs';
import { parseInput } from '../household/parse_input';
import { KID_ROUTINES, KID_ROUTINE_TICKS } from '../kid_routines/routine_refs';
import { choreOccurrencesOn } from '../notifications/day_occurrences';
import { completionKey } from '../notifications/digest_reads';
import { db } from '../shared/firestore';
import { type LinkedFrame, readLinkedFrame } from './frame_access';
import { parsed } from './frame_documents';
import { refuseFrame } from './frame_errors';
import { readFramePremium } from './frame_lunch_photos';
import {
  HANDED_IN_STATUSES,
  HOME_CARE_JOBS,
  JOB_EVENTS,
  WITH_HELPER_STATUSES,
  frameJobShape,
  handInFields,
} from './frame_jobs';
import { GROCERY_ITEMS, frameStoredGroceryItem, groceryTickFields } from './frame_groceries';
import { frameKidRoutineShape, frameKidRoutineTickShape } from './frame_kid_routines';
import { FRAME_DEVICE_OPTIONS, FRAME_TICK_PER_CREDENTIAL } from './frame_policy';
import {
  homeCareRoutineShape,
  homeCareTickShape,
  readMembers,
  readMembersWithGrants,
} from './frame_reads';
import {
  type TickFrameGroceryInput,
  type TickFrameItemInput,
  tickFrameItemInput,
} from './frame_schemas';
import { choreCreditable, creditFor, inTickReach, nextTicks } from './frame_ticks';

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
    if (input.kind === 'grocery') {
      return { status: 'linked', done: await tickGrocery(store, linked, input) };
    }
    if (!inTickReach(input.date, linked.clock.date)) throw refuseFrame('itemOutOfReach');

    const tick = {
      task: tickTask,
      routine: tickRoutine,
      job: handInJob,
      kidRoutine: tickKidRoutine,
    }[input.kind];
    return { status: 'linked', done: await tick(store, linked, input) };
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

async function tickGrocery(
  store: Firestore,
  { frame, home, householdData }: LinkedFrame,
  input: TickFrameGroceryInput,
): Promise<boolean> {
  if (frame.groceries === null) throw refuseFrame('groceriesOff');
  const boughtBy = input.done ? await groceryBuyer(home, householdData, input.by ?? null) : null;
  const ref = home.collection(GROCERY_ITEMS).doc(input.id);
  await store.runTransaction(async (transaction) => {
    const item = parsed(frameStoredGroceryItem, (await transaction.get(ref)).data());
    if (item === null) throw refuseFrame('itemNotFound');
    const fields = groceryTickFields(item, boughtBy);
    if (fields !== null) transaction.update(ref, fields);
  });
  return input.done;
}

async function groceryBuyer(
  home: DocumentReference,
  householdData: LinkedFrame['householdData'],
  by: string | null,
): Promise<string> {
  const { names, groceryEditors } = await readMembersWithGrants(home, householdData);
  const memberId = creditFor(groceryEditors, names, by);
  if (memberId === null) throw refuseFrame('whoNeeded');
  return memberId;
}

async function creditedMember(
  home: DocumentReference,
  assigneeIds: readonly string[],
  by: string | null,
): Promise<string> {
  const { names } = await readMembers(home);
  const memberId = creditFor(choreCreditable(assigneeIds, names), names, by);
  if (memberId === null) throw refuseFrame('whoNeeded');
  return memberId;
}

/**
 * Hands the frame's helper's job in as the app would without an after photo
 * (photo-frames ADR-0020, home-care ADR-0008): the status change and its
 * history event in one transaction. There is no way back from the wall.
 */
async function handInJob(
  store: Firestore,
  { frame, home }: LinkedFrame,
  input: TickFrameItemInput,
): Promise<boolean> {
  if (!(await readFramePremium(store, home))) throw refuseFrame('itemNotFound');
  const ref = home.collection(HOME_CARE_JOBS).doc(input.id);
  return store.runTransaction(async (transaction) => {
    const job = parsed(frameJobShape, (await transaction.get(ref)).data());
    if (
      job === null ||
      job.helperId !== frame.panels.helperMemberId ||
      job.dueDate !== input.date ||
      (input.step ?? null) !== null
    ) {
      throw refuseFrame('itemNotFound');
    }
    if (HANDED_IN_STATUSES.includes(job.status)) {
      if (input.done) return true;
      throw refuseFrame('itemNotFound');
    }
    if (!WITH_HELPER_STATUSES.includes(job.status)) throw refuseFrame('itemNotFound');
    if (!input.done) return false;
    const fields = handInFields(job);
    transaction.update(ref, { ...fields, updatedAt: FieldValue.serverTimestamp() });
    transaction.set(ref.collection(JOB_EVENTS).doc(String(fields.revision)), {
      status: fields.status,
      by: job.helperId,
      note: null,
      at: FieldValue.serverTimestamp(),
    });
    return true;
  });
}

async function tickRoutine(
  store: Firestore,
  { frame, home }: LinkedFrame,
  input: TickFrameItemInput,
): Promise<boolean> {
  if (!(await readFramePremium(store, home))) throw refuseFrame('itemNotFound');
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

/**
 * Ticks a child's routine step, or all of them, by writing the tick the app
 * writes (photo-frames ADR-0021, kid-routines ADR-0001), so `awardRoutineStars`
 * gives the stars without knowing a frame did it. `by` is the child: a routine
 * for one child needs none.
 */
async function tickKidRoutine(
  store: Firestore,
  { frame, home }: LinkedFrame,
  input: TickFrameItemInput,
): Promise<boolean> {
  const routine = parsed(
    frameKidRoutineShape,
    (await home.collection(KID_ROUTINES).doc(input.id).get()).data(),
  );
  const step = input.step ?? null;
  const stepIds = routine?.steps.map((each) => each.id) ?? [];
  if (
    routine === null ||
    !frame.panels.todos ||
    stepIds.length === 0 ||
    !isOccurrence(routine.firstDate, routine.recurrence, input.date) ||
    (step !== null && !stepIds.includes(step))
  ) {
    throw refuseFrame('itemNotFound');
  }
  const { names, kids = [] } = await readMembers(home);
  const eligible = routine.kidIds.filter((id) => kids.includes(id) && names[id] !== undefined);
  const kidId = creditFor(eligible, names, input.by ?? null);
  if (kidId === null) throw refuseFrame('whoNeeded');

  const ref = home.collection(KID_ROUTINE_TICKS).doc(`${input.id}_${kidId}_${input.date}`);
  return store.runTransaction(async (transaction) => {
    const ticked = parsed(frameKidRoutineTickShape, (await transaction.get(ref)).data());
    const doneStepIds = nextTicks(stepIds, ticked?.doneStepIds ?? [], step, input.done);
    transaction.set(ref, {
      routineId: input.id,
      kidId,
      occurrenceDate: input.date,
      doneStepIds,
      updatedBy: kidId,
      updatedAt: FieldValue.serverTimestamp(),
    });
    return doneStepIds.length === stepIds.length;
  });
}
