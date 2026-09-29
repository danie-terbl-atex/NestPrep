import { z } from 'zod';

/**
 * The one notifications callable's body, parsed at the edge and never cast
 * (ENG-09, BE-03). Who the test goes to is the caller, re-derived from the
 * token — there is no field to name anybody else.
 */
export const sendTestNotificationInput = z.object({
  householdId: z.string().trim().min(1).max(64),
});
export type SendTestNotificationInput = z.infer<typeof sendTestNotificationInput>;
