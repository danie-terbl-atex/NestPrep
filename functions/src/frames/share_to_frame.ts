import { FieldValue, type Firestore } from 'firebase-admin/firestore';
import { onCall } from 'firebase-functions/v2/https';
import { z } from 'zod';

import { isFamilyRole } from '../household/access';
import { householdRef, memberRef } from '../household/documents';
import { refuse } from '../household/errors';
import { parseInput, requireUid } from '../household/parse_input';
import { RECIPES } from '../recipes/recipe';
import { readFlag } from '../shared/feature_flags';
import { db } from '../shared/firestore';
import { consumeRateLimit } from '../shared/rate_limit';
import { firstName } from './frame_day';
import { type FrameShareKind, frameDocument, frameRef, framesOf, parsed } from './frame_documents';
import { type FrameRefusal, refuseFrame } from './frame_errors';
import { frameLink } from './frame_links';
import { FRAME_SHARE_PER_UID } from './frame_policy';
import {
  type FrameRecipe,
  type FrameRecipeShareInput,
  buildFrameRecipe,
  frameRecipeDocument,
  frameRecipePhotoPath,
} from './frame_recipe';
import { type ShareToFrameInput, shareToFrameInput } from './frame_schemas';

export interface ShareToFrameResult {
  readonly shared: true;
}

const householdShape = z.object({
  members: z.record(z.string(), z.string()),
  profiles: z.record(z.string(), z.string()).optional().catch(undefined),
});

const memberShape = z.object({ displayName: z.string() });

type ShareContent =
  | { readonly kind: 'page'; readonly url: string; readonly title: string | null }
  | {
      readonly kind: 'recipe';
      readonly title: string;
      readonly recipe: FrameRecipe;
      readonly photoPath: string | null;
    };

export const shareToFrame = onCall(async (request): Promise<ShareToFrameResult> => {
  const uid = requireUid(request.auth);
  const input = parseInput(shareToFrameInput, request.data);
  const store = db();

  const snapshot = await householdRef(store, input.householdId).get();
  if (!snapshot.exists) throw refuse('householdNotFound');
  const household = parsed(householdShape, snapshot.data());
  const role = household?.members[uid];
  if (household === null || role === undefined) throw refuse('notAMember');
  if (!isFamilyRole(role)) throw refuseFrame('notFamily');

  if (!(await readFlag(store, 'photoFrames'))) throw refuseFrame('framesOff');
  if (!(await consumeRateLimit(store, FRAME_SHARE_PER_UID, uid))) {
    throw refuseFrame('tooManyAttempts');
  }

  const content = await shareContent(store, input);
  const by = await senderName(store, input.householdId, household.profiles?.[uid]);
  const ref = frameRef(store, input.householdId, input.frameId);
  await store.runTransaction(async (transaction) => {
    const stored = await transaction.get(ref);
    if (!stored.exists) throw refuseFrame('frameNotFound');
    const frame = frameDocument.parse(stored.data());
    if (!frame.panels.share) throw refuseFrame('sharingOff');
    if (!frame.accepts.includes(kindOf(input))) throw refuseFrame('frameCantOpen');
    if (typeof content === 'string') throw refuseFrame(content);
    transaction.update(ref, {
      share: {
        ...content,
        id: framesOf(store, input.householdId).doc().id,
        by,
        at: FieldValue.serverTimestamp(),
      },
    });
  });
  return { shared: true };
});

function kindOf(input: ShareToFrameInput): FrameShareKind {
  return 'recipe' in input ? 'recipe' : 'page';
}

async function shareContent(
  store: Firestore,
  input: ShareToFrameInput,
): Promise<ShareContent | FrameRefusal> {
  if ('recipe' in input) return recipeContent(store, input.recipe);
  const url = frameLink(input.url);
  return url === null ? 'badLink' : { kind: 'page', url, title: input.title };
}

async function recipeContent(
  store: Firestore,
  share: FrameRecipeShareInput,
): Promise<ShareContent | FrameRefusal> {
  const stored = await store.collection(RECIPES).doc(share.id).get();
  const recipe = stored.exists ? parsed(frameRecipeDocument, stored.data()) : null;
  if (recipe === null) return 'recipeNotFound';
  const built = buildFrameRecipe(recipe, share);
  if (built === null) return 'badRecipe';
  return {
    kind: 'recipe',
    title: built.name,
    recipe: built,
    photoPath: frameRecipePhotoPath(recipe),
  };
}

async function senderName(
  store: Firestore,
  householdId: string,
  memberId: string | undefined,
): Promise<string> {
  if (memberId === undefined) return '';
  const member = parsed(memberShape, (await memberRef(store, householdId, memberId).get()).data());
  return member === null ? '' : firstName(member.displayName);
}
