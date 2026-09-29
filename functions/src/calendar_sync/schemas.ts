import { z } from 'zod';

import { OAUTH_PROVIDERS } from './sync_documents';

/**
 * The calendar sync callables' input, parsed at the edge and never cast
 * (ENG-09, BE-03). Who is calling, which profile they claimed and what role
 * they hold are re-derived, never taken from here.
 */
const householdId = z.string().trim().min(1).max(64);

export const householdInput = z.object({ householdId });
export type HouseholdInput = z.infer<typeof householdInput>;

export const startCalendarConnectionInput = z.object({
  householdId,
  provider: z.enum(OAUTH_PROVIDERS),
});
export type StartCalendarConnectionInput = z.infer<typeof startCalendarConnectionInput>;

export const connectCalendarLinkInput = z.object({
  householdId,
  url: z.string().trim().min(8).max(2048),
});
export type ConnectCalendarLinkInput = z.infer<typeof connectCalendarLinkInput>;

export const connectionInput = z.object({
  householdId,
  connectionId: z.string().trim().min(1).max(64),
});
export type ConnectionInput = z.infer<typeof connectionInput>;
