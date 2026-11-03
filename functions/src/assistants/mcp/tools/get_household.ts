import { z } from 'zod';

import { wallClockOf, knownZoneOr } from '../../../calendar_sync/zoned_time';
import { FAMILY_PROFILES } from '../../../family_profiles/member_details';
import { HOUSEHOLDS, MEMBERS } from '../../../household/documents';
import { ASSISTANT_SCOPES } from '../../assistant_scopes';
import { requireAccess } from '../../assistant_access';
import { ASSISTANT_VIAS } from '../../principal';
import type { AssistantTool } from '../tool';

const WEEKDAYS = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

const storedMember = z.object({
  displayName: z.string().catch(''),
  role: z.string().catch('carer'),
});

const input = z.strictObject({});

const output = z.object({
  household: z.object({
    id: z.string(),
    name: z.string(),
    time_zone: z.string(),
    today: z.string(),
    weekday: z.string(),
  }),
  you: z.object({ member_id: z.string(), first_name: z.string() }),
  members: z.array(
    z.object({ id: z.string(), first_name: z.string(), kind: z.enum(['adult', 'child']) }),
  ),
  connection: z.object({
    assistant: z.enum(ASSISTANT_VIAS),
    may: z.array(z.enum(ASSISTANT_SCOPES)),
  }),
});

/** The first word of a display name: what a family calls each other. */
function firstNameOf(displayName: string): string {
  return displayName.trim().split(/\s+/)[0] ?? '';
}

/**
 * `get_household` (assistants ADR-0001, ADR-0003): the anchor for every other
 * call — the members' first names and ids, adult or child, the household's
 * zone and today's date in it. Nothing else about a person: no birthdays,
 * allergies, medical detail or role beyond adult and child.
 */
export const getHousehold: AssistantTool<typeof input, typeof output> = {
  name: 'get_household',
  title: 'Get the household',
  description:
    'Call this first. Returns the NestPrep household this connection belongs to: its name, its time zone, today\'s date and weekday there, who you are acting as, and every member\'s id and first name, marked adult or child. Use the member ids when an event is for someone ("for Emma"), and work out dates like "Saturday" or "tomorrow" from `today` in the household\'s time zone — never from your own clock. Also lists what this connection may do.',
  scope: 'household:read',
  annotations: {
    readOnlyHint: true,
    destructiveHint: false,
    idempotentHint: true,
    openWorldHint: false,
  },
  input,
  output,
  run: async (store, principal, _input, now) => {
    const access = await requireAccess(store, principal, 'household:read', now);
    const household = store.collection(HOUSEHOLDS).doc(principal.householdId);
    const [members, children] = await Promise.all([
      household.collection(MEMBERS).get(),
      household.collection(FAMILY_PROFILES).where('isChild', '==', true).get(),
    ]);
    const childIds = new Set(children.docs.map((doc) => doc.id));
    const listed = members.docs
      .map((doc) => {
        const member = storedMember.parse(doc.data());
        return {
          id: doc.id,
          first_name: firstNameOf(member.displayName),
          kind:
            member.role === 'kid' || childIds.has(doc.id) ? ('child' as const) : ('adult' as const),
        };
      })
      .sort((a, b) => a.first_name.localeCompare(b.first_name) || a.id.localeCompare(b.id));
    const zone = knownZoneOr(access.household.timeZone);
    const today = wallClockOf(now, zone).date;
    const weekday = WEEKDAYS[(new Date(`${today}T00:00:00Z`).getUTCDay() + 6) % 7] ?? '';
    return {
      household: {
        id: principal.householdId,
        name: access.household.name,
        time_zone: zone,
        today,
        weekday,
      },
      you: {
        member_id: access.memberId,
        first_name: listed.find((member) => member.id === access.memberId)?.first_name ?? '',
      },
      members: listed,
      connection: { assistant: principal.via, may: [...principal.scopes] },
    };
  },
};
