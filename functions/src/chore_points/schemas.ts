import { z } from 'zod';

/**
 * The chore-points callables' input, parsed at the edge and never cast
 * (ENG-09, BE-03). Who is calling, and as which profile, is re-derived from the
 * token and the household — nothing here names a person.
 */
export const reviewChoreInput = z.object({
  householdId: z.string().trim().min(1).max(64),
  completionId: z.string().trim().min(1).max(160),
  decision: z.enum(['approve', 'sendBack']),
});
export type ReviewChoreInput = z.infer<typeof reviewChoreInput>;

export const settleRewardInput = z.object({
  householdId: z.string().trim().min(1).max(64),
  requestId: z.string().trim().min(1).max(64),
  decision: z.enum(['fulfil', 'decline']),
});
export type SettleRewardInput = z.infer<typeof settleRewardInput>;
