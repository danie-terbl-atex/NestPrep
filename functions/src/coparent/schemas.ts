import { z } from 'zod';

import { custodySchedule, home, isoDate, side } from './schedule_schema';

/**
 * Every co-parenting callable's input, parsed at the edge and never cast
 * (ENG-09, BE-03). Who the caller is, which side is theirs and when anything
 * happened are re-derived on the server, never taken from here.
 */

const id = z.string().trim().min(1).max(64);

/** Blank is the same as none, so a cleared field clears. */
function optionalText(max: number): z.ZodType<string | null, string | null> {
  return z
    .string()
    .trim()
    .max(max)
    .nullable()
    .transform((text) => (text === null || text === '' ? null : text));
}

const code = z
  .string()
  .trim()
  .min(4)
  .max(16)
  .transform((value) => value.toUpperCase());

export const createCoParentInviteInput = z.object({
  householdId: id,
  childMemberId: id,
  home,
  schedule: custodySchedule,
});

export const previewCoParentInviteInput = z.object({ code });

export const acceptCoParentInviteInput = z
  .object({
    householdId: id,
    code,
    // Exactly one: a kid profile this home already has, or a name to make one.
    childMemberId: id.nullable(),
    newChildName: z.string().trim().min(1).max(60).nullable(),
    home,
  })
  .refine(
    (input) => (input.childMemberId === null) !== (input.newChildName === null),
    'either an existing child or a new name, not both',
  );

export const confirmCoParentLinkInput = z.object({
  householdId: id,
  linkId: id,
  accept: z.boolean(),
});

export const endCoParentLinkInput = z.object({ householdId: id, linkId: id });

/** The most days one swap may move; longer is a new schedule. */
export const MAX_SWAP_DAYS = 14;

const swapChange = z.object({
  kind: z.literal('swap'),
  from: isoDate,
  to: isoDate,
  toSide: side,
});

const scheduleChange = z.object({ kind: z.literal('schedule'), schedule: custodySchedule });

export const proposeCoParentChangeInput = z.object({
  householdId: id,
  linkId: id,
  change: z.discriminatedUnion('kind', [swapChange, scheduleChange]),
  note: optionalText(300),
});
export type ProposedChange = z.infer<typeof proposeCoParentChangeInput>['change'];

export const answerCoParentChangeInput = z.object({
  householdId: id,
  linkId: id,
  requestId: id,
  answer: z.enum(['accept', 'decline', 'withdraw']),
  note: optionalText(300),
});

const handoverItem = z.object({
  text: z.string().trim().min(1).max(80),
  packed: z.boolean(),
});

export const MAX_HANDOVER_ITEMS = 30;

export const saveCoParentHandoverInput = z.object({
  householdId: id,
  linkId: id,
  date: isoDate,
  items: z.array(handoverItem).max(MAX_HANDOVER_ITEMS),
  medicine: optionalText(300),
  homework: optionalText(300),
  clothes: optionalText(300),
  note: optionalText(500),
});
export type SaveCoParentHandoverInput = z.infer<typeof saveCoParentHandoverInput>;
