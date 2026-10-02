import { z } from 'zod';

import { parseDay } from '../school_letter/plain_date';

/** Which box to picture: one child's lunch on one day (lunch-box ADR-0015). */
export const lunchPhotoInput = z.object({
  householdId: z.string().trim().min(1).max(64),
  childId: z.string().trim().min(1).max(128),
  date: z.string().refine((text) => parseDay(text) !== null),
});
export type LunchPhotoInput = z.infer<typeof lunchPhotoInput>;
