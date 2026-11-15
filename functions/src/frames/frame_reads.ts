import {
  type DocumentReference,
  type Firestore,
  type Query,
  Timestamp,
} from 'firebase-admin/firestore';
import { z } from 'zod';

import { storedRecurrence } from '../chore_points/occurrence_check';
import { addDays, weekdayOf } from '../calendar_sync/zoned_time';
import { MEMBERS } from '../household/documents';
import { MEMBER_LOCATIONS } from '../account_data/personal_refs';
import { PLACES } from '../live_location/location_refs';
import { MEMBER_LIMIT } from '../notifications/household_roster';
import { readChoreRecords, readEventWindow } from '../notifications/digest_reads';
import { type MemberRecord, storedHousehold } from '../notifications/recipients';
import {
  type FrameDaySources,
  type HomeCareDay,
  type MealDay,
  MEAL_SLOTS,
  mondayOf,
  routinesDueOn,
} from './frame_day';
import { readFlag } from '../shared/feature_flags';
import { readKidRoutines } from './frame_kid_routines';
import { type FrameGroceries, parsed } from './frame_documents';
import { HOME_CARE_JOBS, HOME_CARE_SHIFTS, frameMarks, hasFramePhoto } from './frame_jobs';
import { calendarEditors } from './frame_events';
import {
  type FrameGroceriesSources,
  GROCERY_ITEMS,
  frameStoredGroceryItem,
  groceriesEditors,
} from './frame_groceries';
import { readFrameLunch, readFramePremium, type FrameLunch } from './frame_lunch_photos';
import { readFrameMeals } from './frame_meal_photos';
import {
  FRAME_LOCATION_LIMIT,
  FRAME_PLACE_LIMIT,
  type FramePeopleSources,
  frameStoredLocation,
  frameStoredPlace,
} from './frame_people';
import type { FrameMonthSources } from './frame_month';
import {
  FRAME_DAY_AHEAD,
  FRAME_GROCERY_READ_LIMIT,
  FRAME_OVERDUE_DAYS,
  addsEvents,
} from './frame_policy';
import type { FramePanels } from './frame_schemas';

/**
 * The bounded reads a frame's day is made from (`BE-08`): only the areas its
 * panels switch on, every query capped, every document parsed and never cast
 * (`ENG-09`) — one that does not parse is left off the wall, not trusted.
 */

const JOB_LIMIT = 50;
/** One is expected; a phone that was offline can leave a second, and an end closes them all. */
const OPEN_SHIFT_LIMIT = 10;
const HOME_CARE_ROUTINE_LIMIT = 100;

const memberShape = z.object({
  displayName: z.string(),
  color: z.string().optional().catch(undefined),
  role: z.string().catch(''),
  claimedBy: z.string().nullable().catch(null),
  access: z.unknown().optional(),
  look: z.unknown().optional(),
  birthday: z.string().optional().catch(undefined),
});
const nameShape = z.object({ name: z.string() });
const planShape = z.object({ slots: z.record(z.string(), z.string()).catch({}) });
const stepsShape = z
  .array(z.object({ id: z.string(), text: z.string().catch('') }).loose())
  .catch([]);
const jobShape = z.object({
  title: z.string(),
  roomId: z.string(),
  status: z.string(),
  dueDate: z.string(),
  note: z.string().nullable().default(null).catch(null),
  steps: stepsShape,
  doneStepIds: z.array(z.string()).catch([]),
  beforePhoto: z.unknown().optional(),
  marks: z.unknown().optional(),
});
const shiftShape = z.object({ startedAt: z.instanceof(Timestamp) });
export const homeCareRoutineShape = z.object({
  name: z.string(),
  roomId: z.string(),
  helperId: z.string(),
  firstDate: z.string(),
  recurrence: storedRecurrence.nullable().catch(null),
  items: stepsShape,
});
export const homeCareTickShape = z.object({ doneItemIds: z.array(z.string()).catch([]) });

type Sources = Pick<
  FrameDaySources,
  | 'names'
  | 'colors'
  | 'kids'
  | 'looks'
  | 'birthdays'
  | 'adders'
  | 'events'
  | 'chores'
  | 'meals'
  | 'homeCare'
  | 'lunch'
  | 'kidRoutines'
  | 'lunchPhotos'
  | 'groceries'
  | 'people'
>;

export async function readFrameSources(
  store: Firestore,
  home: DocumentReference,
  panels: FramePanels,
  today: string,
  groceries: FrameGroceries | null = null,
): Promise<Sources> {
  const helperId = panels.helperMemberId;
  const premium =
    panels.lunch || panels.people ? readFramePremium(store, home) : Promise.resolve(false);
  const [members, events, chores, meals, homeCare, lunch, groceryItems, whereabouts, kidRoutines] =
    await Promise.all([
      addsEvents(panels) || groceries !== null ? readMembersWithGrants(home) : readMembers(home),
      panels.calendar ? readEventWindow(home, today, addDays(today, FRAME_DAY_AHEAD)) : undefined,
      panels.todos || helperId !== null
        ? readChoreRecords(home, today, addDays(today, -FRAME_OVERDUE_DAYS))
        : undefined,
      panels.meals ? readMeals(store, home, today) : undefined,
      helperId === null ? undefined : readHomeCare(store, home, helperId, today),
      panels.lunch ? readLunch(store, home, today, premium) : undefined,
      groceries === null ? undefined : readGroceryItems(home),
      panels.people ? readPeople(home, premium) : undefined,
      panels.todos ? readKidRoutines(store, home, today) : undefined,
    ]);
  const { groceryEditors, ...people } = { groceryEditors: [], ...members };
  return {
    ...people,
    ...(events === undefined ? {} : { events }),
    ...(chores === undefined ? {} : { chores }),
    ...(meals === undefined ? {} : { meals }),
    ...(homeCare === undefined ? {} : { homeCare }),
    ...lunch,
    ...(groceries === null || groceryItems === undefined
      ? {}
      : { groceries: { shop: groceries.shop, editors: groceryEditors, items: groceryItems } }),
    ...(whereabouts === undefined ? {} : { people: whereabouts }),
    ...(kidRoutines === undefined ? {} : { kidRoutines }),
  };
}

async function readLunch(
  store: Firestore,
  home: DocumentReference,
  today: string,
  premium: Promise<boolean>,
): Promise<FrameLunch | undefined> {
  if (!(await premium)) return undefined;
  return readFrameLunch(store, home, today, premium);
}

async function readPeople(
  home: DocumentReference,
  premium: Promise<boolean>,
): Promise<FramePeopleSources | undefined> {
  if (!(await premium)) return undefined;
  const [locationDocs, placeDocs] = await Promise.all([
    home.collection(MEMBER_LOCATIONS).limit(FRAME_LOCATION_LIMIT).get(),
    home.collection(PLACES).limit(FRAME_PLACE_LIMIT).get(),
  ]);
  return {
    locations: locationDocs.docs.flatMap((doc) => {
      const location = parsed(frameStoredLocation, doc.data());
      return location === null ? [] : [{ ...location, memberId: doc.id }];
    }),
    places: placeDocs.docs.flatMap((doc) => {
      const place = parsed(frameStoredPlace, doc.data());
      return place === null ? [] : [{ ...place, id: doc.id }];
    }),
    now: Date.now(),
  };
}

async function readGroceryItems(home: DocumentReference): Promise<FrameGroceriesSources['items']> {
  const docs = await home
    .collection(GROCERY_ITEMS)
    .orderBy('addedAt', 'desc')
    .limit(FRAME_GROCERY_READ_LIMIT)
    .get();
  return docs.docs.flatMap((doc) => {
    const item = parsed(frameStoredGroceryItem, doc.data());
    return item === null ? [] : [{ ...item, id: doc.id }];
  });
}

export async function readMonthSources(
  home: DocumentReference,
  panels: FramePanels,
  from: string,
  to: string,
): Promise<Pick<FrameMonthSources, 'names' | 'events'>> {
  const [{ names }, events] = await Promise.all([
    readMembers(home),
    panels.calendar ? readEventWindow(home, from, to) : undefined,
  ]);
  return events === undefined ? { names } : { names, events };
}

type FrameMember = MemberRecord & {
  readonly color?: string | undefined;
  readonly look?: unknown;
  readonly birthday?: string | undefined;
};

type MemberSources = Pick<Sources, 'names' | 'colors' | 'kids' | 'looks' | 'birthdays'>;

async function readMemberRecords(home: DocumentReference): Promise<FrameMember[]> {
  const docs = await home.collection(MEMBERS).limit(MEMBER_LIMIT).get();
  return docs.docs.flatMap((doc) => {
    const member = parsed(memberShape, doc.data());
    return member === null ? [] : [{ ...member, id: doc.id }];
  });
}

function namesAndColors(members: readonly FrameMember[]): MemberSources {
  return {
    kids: members.flatMap((member) => (member.role === 'kid' ? [member.id] : [])),
    names: Object.fromEntries(members.map((member) => [member.id, member.displayName])),
    colors: Object.fromEntries(
      members.flatMap((member) =>
        member.color === undefined ? [] : [[member.id, member.color] as const],
      ),
    ),
    looks: Object.fromEntries(
      members.flatMap((member) =>
        member.look === undefined ? [] : [[member.id, member.look] as const],
      ),
    ),
    birthdays: Object.fromEntries(
      members.flatMap((member) =>
        member.birthday === undefined ? [] : [[member.id, member.birthday] as const],
      ),
    ),
  };
}

export async function readMembers(home: DocumentReference): Promise<MemberSources> {
  return namesAndColors(await readMemberRecords(home));
}

/**
 * The members, which of them may add an event from the frame (photo-frames
 * ADR-0008) and which may add to the grocery list (ADR-0012).
 */
export async function readMembersWithGrants(home: DocumentReference): Promise<
  MemberSources & {
    readonly adders: string[];
    readonly groceryEditors: string[];
  }
> {
  const [snapshot, members] = await Promise.all([home.get(), readMemberRecords(home)]);
  const household = parsed(storedHousehold, snapshot.data());
  return {
    ...namesAndColors(members),
    adders: household === null ? [] : calendarEditors(household, members),
    groceryEditors: household === null ? [] : groceriesEditors(household, members),
  };
}

async function namesOf(
  store: Firestore,
  home: DocumentReference,
  collection: string,
  ids: readonly string[],
): Promise<Record<string, string>> {
  const unique = [...new Set(ids)].filter((id) => id !== '');
  if (unique.length === 0) return {};
  const docs = await store.getAll(...unique.map((id) => home.collection(collection).doc(id)));
  return Object.fromEntries(
    docs.flatMap((doc) => {
      const named = parsed(nameShape, doc.data());
      return named === null ? [] : [[doc.id, named.name] as const];
    }),
  );
}

async function readMeals(
  store: Firestore,
  home: DocumentReference,
  today: string,
): Promise<MealDay> {
  const plan = await home.collection('mealPlans').doc(mondayOf(today)).get();
  const slots = parsed(planShape, plan.data())?.slots ?? {};
  const weekday = String(weekdayOf(today));
  const todays = MEAL_SLOTS.flatMap((slot) => slots[`${weekday}_${slot}`] ?? []);
  const { names, photos } = await readFrameMeals(store, home, todays);
  return { slots, mealNames: names, photos };
}

async function readHomeCare(
  store: Firestore,
  home: DocumentReference,
  helperId: string,
  today: string,
): Promise<HomeCareDay> {
  const [jobDocs, routineDocs, shiftStartedAt] = await Promise.all([
    home
      .collection(HOME_CARE_JOBS)
      .where('helperId', '==', helperId)
      .where('dueDate', '>=', addDays(today, -FRAME_OVERDUE_DAYS))
      .where('dueDate', '<=', today)
      .limit(JOB_LIMIT)
      .get(),
    home
      .collection('homeCareRoutines')
      .where('helperId', '==', helperId)
      .limit(HOME_CARE_ROUTINE_LIMIT)
      .get(),
    readOpenShift(store, home, helperId),
  ]);
  const jobs = jobDocs.docs.flatMap((doc) => {
    const job = parsed(jobShape, doc.data());
    if (job === null) return [];
    const { beforePhoto, marks, ...shown } = job;
    return [
      {
        ...shown,
        id: doc.id,
        hasPhoto: hasFramePhoto(doc.id, beforePhoto),
        marks: frameMarks(marks),
      },
    ];
  });
  const routines = routineDocs.docs.flatMap((doc) => {
    const routine = parsed(homeCareRoutineShape, doc.data());
    return routine === null ? [] : [{ ...routine, id: doc.id }];
  });
  const due = routinesDueOn(today, routines);
  const tickDocs =
    due.length === 0
      ? []
      : await store.getAll(
          ...due.map((routine) =>
            home.collection('homeCareRoutineTicks').doc(`${routine.id}_${today}`),
          ),
        );
  const ticks = Object.fromEntries(
    tickDocs.flatMap((doc, index) => {
      const tick = parsed(homeCareTickShape, doc.data());
      const routine = due[index];
      return tick === null || routine === undefined
        ? []
        : [[routine.id, tick.doneItemIds] as const];
    }),
  );
  const rooms = await namesOf(store, home, 'homeCareRooms', [
    ...jobs.map((job) => job.roomId),
    ...due.map((routine) => routine.roomId),
  ]);
  return {
    jobs,
    routines: due,
    ticks,
    rooms,
    ...(shiftStartedAt === undefined ? {} : { shiftStartedAt }),
  };
}

/** When the helper clocked in, null while she is out, undefined while shifts are off. */
async function readOpenShift(
  store: Firestore,
  home: DocumentReference,
  helperId: string,
): Promise<Date | null | undefined> {
  if (!(await readFlag(store, 'homeCareShifts'))) return undefined;
  const open = await openShiftsOf(home, helperId).get();
  const shift = parsed(shiftShape, open.docs[0]?.data());
  return shift === null ? null : shift.startedAt.toDate();
}

/** The helper's open shift; equality only, so it needs no composite index. */
export function openShiftsOf(home: DocumentReference, helperId: string): Query {
  return home
    .collection(HOME_CARE_SHIFTS)
    .where('helperId', '==', helperId)
    .where('status', '==', 'open')
    .limit(OPEN_SHIFT_LIMIT);
}
