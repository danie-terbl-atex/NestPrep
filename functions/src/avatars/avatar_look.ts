import { z } from 'zod';

import { ACCESSORIES, NESTLINGS, type AvatarSlot } from './avatar_catalogue';
import { ADULT_STAGE, AVATAR_STAGES, type AvatarStage } from './avatar_stage';

/**
 * A member's choice, what they own, and the look mirrored onto the member
 * (avatars ADR-0001), parsed and decided here without a database.
 */

export const AVATAR_SLOTS = [
  'top',
  'badge',
  'ring',
  'face',
] as const satisfies readonly AvatarSlot[];

export const AVATAR_HASH = /^[0-9a-f]{32}$/;

export type AvatarWear = Partial<Record<AvatarSlot, string>>;

export interface AvatarChoice {
  readonly base: string;
  readonly stage?: AvatarStage;
  readonly wear: AvatarWear;
}

export interface AvatarOwned {
  readonly accessories: readonly string[];
  readonly images: readonly string[];
}

export interface AvatarLook {
  readonly v: 1;
  readonly base: string | null;
  readonly stage: AvatarStage;
  readonly wear: AvatarWear;
}

const stage = z.union(AVATAR_STAGES.map((value) => z.literal(value)));
const wear = z.strictObject({
  top: z.string().optional(),
  badge: z.string().optional(),
  ring: z.string().optional(),
  face: z.string().optional(),
});

const storedChoice = z.strictObject({ base: z.string(), stage: stage.optional(), wear });
const storedOwned = z.object({
  accessories: z.array(z.string()).catch([]),
  images: z.array(z.string()).catch([]),
});
const storedLook = z.object({
  v: z.literal(1),
  base: z.string().nullable(),
  stage,
  wear,
});

export const NO_OWNED: AvatarOwned = { accessories: [], images: [] };

function withoutUndefined(worn: z.infer<typeof wear>): AvatarWear {
  return Object.fromEntries(
    AVATAR_SLOTS.flatMap((slot) => {
      const id = worn[slot];
      return id === undefined ? [] : [[slot, id] as const];
    }),
  );
}

export function parseChoice(value: unknown): AvatarChoice | undefined {
  const parsed = storedChoice.safeParse(value);
  if (!parsed.success) return undefined;
  const { base, stage: chosen } = parsed.data;
  return {
    base,
    ...(chosen === undefined ? {} : { stage: chosen }),
    wear: withoutUndefined(parsed.data.wear),
  };
}

export function parseOwned(value: unknown): AvatarOwned {
  const parsed = storedOwned.safeParse(value);
  return parsed.success ? parsed.data : NO_OWNED;
}

export function parseLook(value: unknown): AvatarLook | undefined {
  const parsed = storedLook.safeParse(value);
  return parsed.success ? { ...parsed.data, wear: withoutUndefined(parsed.data.wear) } : undefined;
}

export function nestlingOf(base: string | null): string | undefined {
  if (base === null || !base.startsWith('preset:')) return undefined;
  const name = base.slice('preset:'.length);
  return NESTLINGS.some((nestling) => nestling.name === name) ? name : undefined;
}

export function imageOf(base: string | null): string | undefined {
  if (base === null || !base.startsWith('image:')) return undefined;
  const hash = base.slice('image:'.length);
  return AVATAR_HASH.test(hash) ? hash : undefined;
}

export function isAvatarHash(value: unknown): value is string {
  return typeof value === 'string' && AVATAR_HASH.test(value);
}

export function accessoryOf(id: string): (typeof ACCESSORIES)[number] | undefined {
  return ACCESSORIES.find((accessory) => accessory.id === id);
}

function baseIsAllowed(base: string, owned: AvatarOwned): boolean {
  if (base === 'initial') return true;
  if (nestlingOf(base) !== undefined) return true;
  const image = imageOf(base);
  return image !== undefined && owned.images.includes(image);
}

/** Whether [id] is an accessory for [slot] on [base]; a face goes only on a Nestling. */
export function fitsSlot(id: string, slot: AvatarSlot, base: string | null): boolean {
  if (accessoryOf(id)?.slot !== slot) return false;
  return slot !== 'face' || nestlingOf(base) !== undefined;
}

/**
 * Whether [id] may be worn in [slot] on [base]: it fits there, and is free or
 * owned. Only kids earn stars, so anyone else may wear any accessory
 * ([wearsAll], Daniel 2026-11-13).
 */
export function mayWear(
  id: string,
  slot: AvatarSlot,
  base: string | null,
  owned: AvatarOwned,
  wearsAll = false,
): boolean {
  if (!fitsSlot(id, slot, base)) return false;
  return wearsAll || accessoryOf(id)?.stars === 0 || owned.accessories.includes(id);
}

export function isValidChoice(choice: AvatarChoice, owned: AvatarOwned, wearsAll = false): boolean {
  if (!baseIsAllowed(choice.base, owned)) return false;
  return AVATAR_SLOTS.every((slot) => {
    const id = choice.wear[slot];
    return id === undefined || mayWear(id, slot, choice.base, owned, wearsAll);
  });
}

/** [choice] with whatever may not be worn taken off, and an unknown base made the initial. */
export function sanitized(
  choice: AvatarChoice,
  owned: AvatarOwned,
  wearsAll = false,
): AvatarChoice {
  const base = baseIsAllowed(choice.base, owned) ? choice.base : 'initial';
  const worn = Object.fromEntries(
    AVATAR_SLOTS.flatMap((slot) => {
      const id = choice.wear[slot];
      return id !== undefined && mayWear(id, slot, base, owned, wearsAll)
        ? [[slot, id] as const]
        : [];
    }),
  );
  return { ...choice, base, wear: worn };
}

/** The last valid choice, read back from the look it was mirrored into. */
export function choiceOfLook(
  look: AvatarLook | undefined,
  isKid: boolean,
  owned: AvatarOwned,
): AvatarChoice {
  if (look === undefined) return { base: 'initial', wear: {} };
  return sanitized(
    {
      base: look.base ?? 'initial',
      ...(isKid ? {} : { stage: look.stage }),
      wear: look.wear,
    },
    owned,
    !isKid,
  );
}

export function lookOf(choice: AvatarChoice, stageNow: AvatarStage): AvatarLook {
  return {
    v: 1,
    base: choice.base === 'initial' ? null : choice.base,
    stage: stageNow,
    wear: choice.wear,
  };
}

export function adultStage(choice: AvatarChoice): AvatarStage {
  return choice.stage ?? ADULT_STAGE;
}

export function sameLook(a: AvatarLook | undefined, b: AvatarLook): boolean {
  return (
    a !== undefined &&
    a.base === b.base &&
    a.stage === b.stage &&
    AVATAR_SLOTS.every((slot) => a.wear[slot] === b.wear[slot])
  );
}
