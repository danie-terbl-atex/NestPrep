import { readFile } from 'node:fs/promises';
import { resolve } from 'node:path';

import type { Firestore } from 'firebase-admin/firestore';

import type { ModelPart } from '../ai/generative_model';
import { addDays } from '../calendar_sync/zoned_time';
import { MEMBERS, householdRef } from '../household/documents';
import { MEMBER_LIMIT } from '../notifications/household_roster';
import type { ObjectStore } from '../shared/storage';
import { MOMENTS, nestlingAssetId } from './avatar_catalogue';
import { imageOf, nestlingOf, parseLook } from './avatar_look';
import { type Hemisphere, isBirthdayOn, momentIsOn } from './avatar_moments';
import { AVATAR_KEEPSAKES, AVATAR_MADE_MAX_BYTES, avatarImagePath } from './avatar_refs';
import { ADULT_STAGE, type AvatarStage } from './avatar_stage';

export const PORTRAIT_MEMBER_LIMIT = 8;

export const NESTLING_ASSETS = resolve(__dirname, '../../assets/avatars');

export const COLOUR_NESTLINGS: Readonly<Record<string, string>> = {
  violet: 'bramble',
  pink: 'rosie',
  coral: 'pip',
  amber: 'sunny',
  lime: 'ziggy',
  mint: 'olive',
  teal: 'jewel',
  sky: 'splash',
  indigo: 'nova',
  plum: 'ember',
};

export function colourNestling(colour: unknown): string {
  return (typeof colour === 'string' ? COLOUR_NESTLINGS[colour] : undefined) ?? 'pip';
}

export interface PortraitMember {
  readonly id: string;
  readonly role: unknown;
  readonly color: unknown;
  readonly look: unknown;
}

export type PortraitReference =
  | { readonly kind: 'nestling'; readonly assetId: string }
  | { readonly kind: 'creation'; readonly path: string };

const LEFT_OUT_ROLES: readonly unknown[] = ['helper', 'carer'];

/**
 * Who sits in the nest and as what: a Nestling at its stage, or a creation
 * the member wears; a photo avatar, the initial or no look at all is the
 * Nestling of the member's colour, so a photo of a person is never sent.
 */
export function portraitPlan(
  householdId: string,
  members: readonly PortraitMember[],
  creations: ReadonlySet<string>,
): PortraitReference[] {
  return members
    .filter((member) => !LEFT_OUT_ROLES.includes(member.role))
    .slice(0, PORTRAIT_MEMBER_LIMIT)
    .map((member) => {
      const look = parseLook(member.look);
      const nestling = nestlingOf(look?.base ?? null);
      const image = imageOf(look?.base ?? null);
      if (image !== undefined && creations.has(`${member.id}/${image}`)) {
        return { kind: 'creation', path: avatarImagePath(householdId, member.id, image) };
      }
      const stage: AvatarStage = look?.stage ?? (member.role === 'kid' ? 1 : ADULT_STAGE);
      return {
        kind: 'nestling',
        assetId: nestlingAssetId(nestling ?? colourNestling(member.color), stage),
      };
    });
}

const SEASONS: Readonly<Record<Hemisphere, readonly string[]>> = {
  south: [
    'summer',
    'summer',
    'autumn',
    'autumn',
    'autumn',
    'winter',
    'winter',
    'winter',
    'spring',
    'spring',
    'spring',
    'summer',
  ],
  north: [
    'winter',
    'winter',
    'spring',
    'spring',
    'spring',
    'summer',
    'summer',
    'summer',
    'autumn',
    'autumn',
    'autumn',
    'winter',
  ],
};

const SEASON_SCENES: Readonly<Record<string, string>> = {
  summer: 'A sunny summer’s day, with flowers and a blue sky',
  autumn: 'A golden autumn day, with falling leaves',
  winter: 'A cosy winter’s day, with soft blankets and warm scarves',
  spring: 'A bright spring day, with blossom on the branches',
};

const MOMENT_SCENES: Readonly<Record<string, string>> = {
  'moment-birthday-hat': 'A birthday this week: party hats, bunting and a cake with candles',
  'moment-festive-hat': 'The festive season: fairy lights and wrapped presents',
  'moment-new-year-crown': 'New Year: paper crowns and streamers',
  'moment-easter-ears': 'Easter: painted eggs hidden in the grass',
  'moment-valentine-heart': 'Valentine’s Day: little paper hearts',
  'moment-spooky-hat': 'Halloween: friendly smiling pumpkins',
  'moment-heritage-braai-hat': 'Heritage Day: a sunny family braai',
};

/** The week's moment when there is one the nest can dress for, otherwise the season. */
export function portraitScene(
  today: string,
  hemisphere: Hemisphere,
  birthdays: readonly (string | null | undefined)[],
): string {
  const week = Array.from({ length: 7 }, (_, offset) => addDays(today, offset));
  if (week.some((day) => birthdays.some((birthday) => isBirthdayOn(birthday, day)))) {
    return MOMENT_SCENES['moment-birthday-hat'] ?? '';
  }
  for (const moment of MOMENTS) {
    const scene = MOMENT_SCENES[moment.id];
    if (scene === undefined || moment.rule.kind === 'birthday') continue;
    if (week.some((day) => momentIsOn(moment.rule, { today: day, hemisphere }))) return scene;
  }
  const season = SEASONS[hemisphere][Number(today.slice(5, 7)) - 1] ?? 'spring';
  return SEASON_SCENES[season] ?? '';
}

export interface PortraitSitting {
  readonly references: ModelPart[];
  readonly birthdays: (string | null | undefined)[];
}

export async function portraitSitting(
  store: Firestore,
  objects: ObjectStore,
  householdId: string,
): Promise<PortraitSitting> {
  const home = householdRef(store, householdId);
  const [memberDocs, keepsakes] = await Promise.all([
    home.collection(MEMBERS).orderBy('displayName').limit(MEMBER_LIMIT).get(),
    home.collection(AVATAR_KEEPSAKES).select('memberId', 'imageHash').limit(500).get(),
  ]);
  const creations = new Set(
    keepsakes.docs.map((doc) => `${String(doc.get('memberId'))}/${String(doc.get('imageHash'))}`),
  );
  const members = memberDocs.docs.map((doc) => ({
    id: doc.id,
    role: doc.get('role') as unknown,
    color: doc.get('color') as unknown,
    look: doc.get('look') as unknown,
    birthday: doc.get('birthday') as unknown,
  }));
  const plan = portraitPlan(householdId, members, creations);
  const references = await Promise.all(plan.map((reference) => partOf(objects, reference)));
  return {
    references: references.filter((part): part is ModelPart => part !== null),
    birthdays: members
      .filter((member) => !LEFT_OUT_ROLES.includes(member.role))
      .map((member) => (typeof member.birthday === 'string' ? member.birthday : null)),
  };
}

async function partOf(
  objects: ObjectStore,
  reference: PortraitReference,
): Promise<ModelPart | null> {
  if (reference.kind === 'creation') {
    const bytes = await objects.read(reference.path, 'image/jpeg', AVATAR_MADE_MAX_BYTES);
    return bytes === null
      ? null
      : { kind: 'inline', mimeType: 'image/jpeg', base64: bytes.toString('base64') };
  }
  try {
    const bytes = await readFile(resolve(NESTLING_ASSETS, `${reference.assetId}.webp`));
    return { kind: 'inline', mimeType: 'image/webp', base64: bytes.toString('base64') };
  } catch {
    return null;
  }
}
