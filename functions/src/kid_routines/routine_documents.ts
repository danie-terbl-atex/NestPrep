import { z } from 'zod';

import { storedRecurrence } from '../chore_points/occurrence_check';

/**
 * The stored shapes a routine's stars read, parsed and never cast (`ENG-09`).
 *
 * The routine and its tick are written by the Flutter client and the rules
 * cannot look inside `steps`, so one that does not parse earns nothing
 * (`BE-10`). Only what the award needs is read; the rest is the client's.
 */

export const storedKidRoutine = z.object({
  name: z.string(),
  kidIds: z.array(z.string()),
  firstDate: z.string(),
  recurrence: storedRecurrence.nullable().default(null),
  points: z.number().int().min(0).max(20).default(0),
  steps: z.array(z.object({ id: z.string() })),
});
export type StoredKidRoutine = z.infer<typeof storedKidRoutine>;

export const storedRoutineTick = z.object({
  routineId: z.string(),
  kidId: z.string(),
  occurrenceDate: z.string(),
  doneStepIds: z.array(z.string()),
});
export type StoredRoutineTick = z.infer<typeof storedRoutineTick>;

export const AWARD_STATUSES = ['awarded', 'withdrawn'] as const;

export const storedRoutineAward = z.object({
  memberId: z.string(),
  routineId: z.string(),
  occurrenceDate: z.string(),
  title: z.string(),
  points: z.number().int(),
  status: z.enum(AWARD_STATUSES),
  round: z.number().int().min(0),
});
export type StoredRoutineAward = z.infer<typeof storedRoutineAward>;
