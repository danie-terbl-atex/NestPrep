import { Timestamp } from 'firebase-admin/firestore';
import { z } from 'zod';

import { refuseCoParent } from './errors';
import { custodySchedule, home } from './schedule_schema';

/**
 * A code one home made for another (household ADR-0004), as the two calls that
 * read it — preview and accept — need it. Parsed, never cast (ENG-09): a code
 * written by an older build, or damaged, reads as no code at all.
 */
const inviteShape = z.object({
  householdId: z.string().min(1),
  childMemberId: z.string().min(1),
  childName: z.string().min(1),
  home,
  schedule: custodySchedule,
  expiresAt: z.instanceof(Timestamp),
  redeemedBy: z.string().nullable(),
});
export type LinkInvite = z.infer<typeof inviteShape>;

/** The invite, or the refusal that says why it cannot be used now. */
export function usableInvite(data: unknown, now: number = Date.now()): LinkInvite {
  const invite = inviteShape.safeParse(data);
  if (!invite.success) throw refuseCoParent('linkInviteNotFound');
  if (invite.data.redeemedBy !== null) throw refuseCoParent('linkInviteUsed');
  if (invite.data.expiresAt.toMillis() <= now) throw refuseCoParent('linkInviteExpired');
  return invite.data;
}
