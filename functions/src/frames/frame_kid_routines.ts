import type { DocumentReference, Firestore } from 'firebase-admin/firestore';
import { z } from 'zod';

import { weekdayOf } from '../calendar_sync/zoned_time';
import { isOccurrence, storedRecurrence } from '../chore_points/occurrence_check';
import { KID_ROUTINES, KID_ROUTINE_TICKS } from '../kid_routines/routine_refs';
import { readFlag } from '../shared/feature_flags';
import { parsed } from './frame_documents';

/**
 * Children's routines on a frame (C-0023 rev 21, photo-frames ADR-0021): one
 * entry per routine and child that falls today, with every step's picture,
 * note and today's things to remember, and whether that child has done it.
 *
 * The routine is the client's to write and the rules cannot look inside
 * `steps`, so one that does not parse is not shown (`BE-10`).
 */

export const FRAME_KID_ROUTINE_LIMIT = 100;
export const FRAME_KID_ROUTINE_TICK_LIMIT = 300;

export const KID_ROUTINE_SLOTS = ['morning', 'afternoon', 'bedtime'] as const;
export type KidRoutineSlot = (typeof KID_ROUTINE_SLOTS)[number];

const picture = z.string().nullish();

export const frameKidRoutineShape = z.object({
  name: z.string(),
  slot: z.enum(KID_ROUTINE_SLOTS).catch('morning'),
  kidIds: z.array(z.string()),
  firstDate: z.string(),
  recurrence: storedRecurrence.nullable().default(null),
  finishBy: z.number().int().min(0).max(1439).nullable().catch(null).default(null),
  points: z.number().int().min(0).max(20).catch(0).default(0),
  steps: z.array(
    z.object({
      id: z.string(),
      title: z.string(),
      picture,
      note: z.string().nullish(),
      parts: z
        .array(
          z.object({
            text: z.string(),
            picture,
            weekdays: z.array(z.number().int()).catch([]).default([]),
          }),
        )
        .catch([])
        .default([]),
    }),
  ),
});
export type FrameKidRoutineRecord = z.infer<typeof frameKidRoutineShape> & { readonly id: string };

export const frameKidRoutineTickShape = z.object({
  routineId: z.string(),
  kidId: z.string(),
  doneStepIds: z.array(z.string()),
});

export interface KidRoutineSources {
  readonly routines: readonly FrameKidRoutineRecord[];
  /** `{routineId}_{kidId}` → the steps that child ticked today. */
  readonly done: Readonly<Record<string, readonly string[]>>;
}

export interface FrameRoutineStep {
  readonly id: string;
  readonly title: string;
  readonly done: boolean;
  readonly picture?: string;
  readonly note?: string;
  readonly parts?: { readonly text: string; readonly picture?: string }[];
}

/** `id`, `who` and `date` are what a tick sends back, with a step's `id`. */
export interface FrameKidRoutine {
  readonly id: string;
  readonly name: string;
  readonly slot: KidRoutineSlot;
  readonly who: string;
  readonly date: string;
  readonly done: boolean;
  readonly stars?: number;
  /** `HH:MM` on the household's clock. */
  readonly finishBy?: string;
  readonly steps: FrameRoutineStep[];
}

export const tickKey = (routineId: string, kidId: string): string => `${routineId}_${kidId}`;

/** In the order a day runs, then by child, then by name. */
export function kidRoutinesPanel(
  sources: KidRoutineSources,
  today: string,
  kidNames: Readonly<Record<string, string>>,
  clockTime: (minute: number | null) => string | null,
): FrameKidRoutine[] {
  const weekday = weekdayOf(today);
  return sources.routines
    .filter(
      (routine) =>
        routine.steps.length > 0 && isOccurrence(routine.firstDate, routine.recurrence, today),
    )
    .flatMap((routine) =>
      routine.kidIds.flatMap((kidId): FrameKidRoutine[] => {
        const who = kidNames[kidId];
        if (who === undefined || who === '') return [];
        const ticked = sources.done[tickKey(routine.id, kidId)] ?? [];
        const steps = routine.steps.map((step): FrameRoutineStep => {
          const parts = step.parts
            .filter((part) => part.weekdays.length === 0 || part.weekdays.includes(weekday))
            .map((part) => ({
              text: part.text,
              ...(part.picture ? { picture: part.picture } : {}),
            }));
          return {
            id: step.id,
            title: step.title,
            done: ticked.includes(step.id),
            ...(step.picture ? { picture: step.picture } : {}),
            ...(step.note ? { note: step.note } : {}),
            ...(parts.length > 0 ? { parts } : {}),
          };
        });
        const finishBy = clockTime(routine.finishBy);
        return [
          {
            id: routine.id,
            name: routine.name,
            slot: routine.slot,
            who,
            date: today,
            done: steps.every((step) => step.done),
            ...(routine.points > 0 ? { stars: routine.points } : {}),
            ...(finishBy === null ? {} : { finishBy }),
            steps,
          },
        ];
      }),
    )
    .sort(
      (a, b) =>
        KID_ROUTINE_SLOTS.indexOf(a.slot) - KID_ROUTINE_SLOTS.indexOf(b.slot) ||
        a.who.localeCompare(b.who) ||
        a.name.localeCompare(b.name),
    );
}

/** Undefined while `kidRoutines` is switched off, so the day carries no block at all. */
export async function readKidRoutines(
  store: Firestore,
  home: DocumentReference,
  today: string,
): Promise<KidRoutineSources | undefined> {
  if (!(await readFlag(store, 'kidRoutines'))) return undefined;
  const [routineDocs, tickDocs] = await Promise.all([
    home.collection(KID_ROUTINES).limit(FRAME_KID_ROUTINE_LIMIT).get(),
    home
      .collection(KID_ROUTINE_TICKS)
      .where('occurrenceDate', '==', today)
      .limit(FRAME_KID_ROUTINE_TICK_LIMIT)
      .get(),
  ]);
  return {
    routines: routineDocs.docs.flatMap((doc) => {
      const routine = parsed(frameKidRoutineShape, doc.data());
      return routine === null ? [] : [{ ...routine, id: doc.id }];
    }),
    done: Object.fromEntries(
      tickDocs.docs.flatMap((doc) => {
        const tick = parsed(frameKidRoutineTickShape, doc.data());
        return tick === null
          ? []
          : [[tickKey(tick.routineId, tick.kidId), tick.doneStepIds] as const];
      }),
    ),
  };
}
