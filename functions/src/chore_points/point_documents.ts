import type { DocumentSnapshot } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { z } from 'zod';

import { storedRecurrence } from './occurrence_check';

/**
 * The stored shapes chore points read, parsed and never cast (`ENG-09`).
 *
 * Tasks, routines and completions are written by the Flutter client; the rules
 * check their keys and not every value, so a document that does not parse is
 * treated as one that earns nothing, and logged — never trusted and never a
 * crash in a trigger that would then retry for ever (`BE-10`).
 */

export const storedTask = z.object({
  title: z.string(),
  dueDate: z.string(),
  recurrence: storedRecurrence.nullable().default(null),
  assigneeIds: z.array(z.string()).default([]),
  routineId: z.string().nullable().default(null),
  points: z.number().int().min(0).max(100).default(0),
  needsApproval: z.boolean().default(false),
});
export type StoredTask = z.infer<typeof storedTask>;

export const storedRoutine = z.object({
  firstDate: z.string(),
  recurrence: storedRecurrence.nullable().default(null),
  defaultAssigneeIds: z.array(z.string()).default([]),
});
export type StoredRoutine = z.infer<typeof storedRoutine>;

export const storedCompletion = z.object({
  taskId: z.string(),
  occurrenceDate: z.string(),
  completedBy: z.string(),
  completedFor: z.string(),
});
export type StoredCompletion = z.infer<typeof storedCompletion>;

export const CLAIM_STATUSES = ['pending', 'awarded', 'sentBack', 'withdrawn'] as const;
export type ClaimStatus = (typeof CLAIM_STATUSES)[number];

export const storedClaim = z.object({
  memberId: z.string(),
  taskId: z.string(),
  occurrenceDate: z.string(),
  title: z.string(),
  points: z.number().int(),
  status: z.enum(CLAIM_STATUSES),
  round: z.number().int().min(0),
});
export type StoredClaim = z.infer<typeof storedClaim>;

export const storedBalance = z.object({
  balance: z.number().int().default(0),
  earned: z.number().int().default(0),
  spent: z.number().int().default(0),
  streakDays: z.number().int().default(0),
  bestStreak: z.number().int().default(0),
  streakLastDay: z.string().nullable().default(null),
});
export type StoredBalance = z.infer<typeof storedBalance>;

export const storedReward = z.object({
  title: z.string(),
  cost: z.number().int().min(1),
  icon: z.string().default('gift'),
});
export type StoredReward = z.infer<typeof storedReward>;

export const REQUEST_STATUSES = ['waiting', 'fulfilled', 'declined', 'refused'] as const;
export type RequestStatus = (typeof REQUEST_STATUSES)[number];

/** A request as the client made it, and the status only Functions add. */
export const storedRequest = z.object({
  rewardId: z.string(),
  memberId: z.string(),
  requestedBy: z.string(),
  status: z.enum(REQUEST_STATUSES).optional(),
  cost: z.number().int().optional(),
});
export type StoredRequest = z.infer<typeof storedRequest>;

/**
 * A snapshot's data through [schema], or undefined when the document is
 * missing or does not have the shape — the second logged with the path, never
 * the contents (`ENG-22`).
 */
export function parseSnapshot<T extends z.ZodType>(
  snapshot: DocumentSnapshot,
  schema: T,
): z.infer<T> | undefined {
  if (!snapshot.exists) return undefined;
  const result = schema.safeParse(snapshot.data());
  if (result.success) return result.data;
  logger.warn('chore points: a stored document did not parse', { path: snapshot.ref.path });
  return undefined;
}
