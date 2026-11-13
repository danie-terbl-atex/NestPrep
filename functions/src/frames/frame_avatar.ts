import type { DocumentReference } from 'firebase-admin/firestore';

import { nestlingAssetId } from '../avatars/avatar_catalogue';
import { AVATAR_SLOTS, fitsSlot, imageOf, nestlingOf, parseLook } from '../avatars/avatar_look';
import { type AvatarLayer, type Hemisphere, layersOn } from '../avatars/avatar_moments';
import { avatarImagePath } from '../avatars/avatar_refs';
import { MEMBERS } from '../household/documents';
import { MEMBER_LIMIT } from '../notifications/household_roster';

/**
 * A member's avatar as the wall draws it (C-0023 rev 18, rev 19): the base
 * already resolved to a bundled Nestling at its stage, a picture to fetch or
 * the initial the member chose, then the layers worn today. The frame never
 * computes anything.
 */

export interface FrameAvatar {
  readonly base:
    { readonly preset: string } | { readonly image: string } | { readonly initial: true };
  readonly layers: AvatarLayer[];
}

export function frameAvatarOf(
  look: unknown,
  day: {
    readonly today: string;
    readonly hemisphere: Hemisphere;
    readonly birthday?: string | null;
  },
): FrameAvatar | undefined {
  const parsed = parseLook(look);
  if (parsed === undefined) return undefined;
  const nestling = nestlingOf(parsed.base);
  const image = imageOf(parsed.base);
  const base =
    nestling !== undefined
      ? { preset: nestlingAssetId(nestling, parsed.stage) }
      : image !== undefined
        ? { image }
        : parsed.base === null
          ? { initial: true as const }
          : undefined;
  if (base === undefined) return undefined;
  const wear = Object.fromEntries(
    AVATAR_SLOTS.flatMap((slot) => {
      const id = parsed.wear[slot];
      return id !== undefined && fitsSlot(id, slot, parsed.base) ? [[slot, id] as const] : [];
    }),
  );
  return { base, layers: layersOn(wear, day, nestling !== undefined) };
}

/** Where a current member's picture base is, or null when [hash] is nobody's now. */
export async function frameAvatarPath(
  home: DocumentReference,
  hash: string,
): Promise<string | null> {
  const members = await home.collection(MEMBERS).limit(MEMBER_LIMIT).get();
  const member = members.docs.find(
    (doc) => imageOf(parseLook(doc.get('look'))?.base ?? null) === hash,
  );
  return member === undefined ? null : avatarImagePath(home.id, member.id, hash);
}
