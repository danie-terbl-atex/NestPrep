import { z } from 'zod';

/**
 * Ending a shift (nanny-hub ADR-0002), parsed at the edge and never cast
 * (ENG-09, BE-03). The closing note is the carer's last word to the parents,
 * bounded like any entry's note; blank is the same as none.
 */
export const endNannyShiftInput = z.object({
  householdId: z.string().trim().min(1).max(64),
  shiftId: z.string().trim().min(1).max(64),
  closingNote: z
    .string()
    .trim()
    .max(500)
    .nullable()
    .transform((note) => (note === null || note === '' ? null : note)),
});
export type EndNannyShiftInput = z.infer<typeof endNannyShiftInput>;
