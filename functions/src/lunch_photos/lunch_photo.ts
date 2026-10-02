import type { Firestore } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { onCall } from 'firebase-functions/v2/https';

import { imageRuntime } from '../ai/ai_runtime';
import { runImageCall } from '../ai/run_ai_call';
import { tierFrom } from '../ai/usage_rules';
import { householdRef } from '../household/documents';
import { parseInput, requireUid } from '../household/parse_input';
import { mondayOf, weekKeyOf } from '../plan_week/iso_week';
import { LUNCH_PLANS, planFrom } from '../plan_week/week_documents';
import { isoWeekday } from '../school_letter/plain_date';
import { db } from '../shared/firestore';
import { objectStore } from '../shared/storage';
import { premiumRequired } from '../subscriptions/errors';
import { entitlementRef } from '../subscriptions/subscription_documents';
import { boxOn, combinationOf, promptFor, type LunchBox } from './combination';
import { refuseLunchPhoto } from './errors';
import { photoCallerIn } from './photo_caller';
import { claimPhoto, markReady, photoPlace, releaseClaim } from './photo_documents';
import { lunchPhotoInput, type LunchPhotoInput } from './schemas';

/**
 * `ready` carries the Storage path the app loads the picture from; `pending`
 * means another request is making it right now, and the app asks again.
 */
export type LunchPhotoResult =
  { readonly status: 'ready'; readonly path: string } | { readonly status: 'pending' };

/** A year: a picture under a key never changes, because a new prompt is a new key. */
const PHOTO_CACHE_CONTROL = 'public, max-age=31536000';

/**
 * The picture of one child's lunch box on one day (lunch-box ADR-0015): an
 * image the model makes of exactly that combination, the first time anybody
 * asks for it, and the cached one after that. A box of catalogue foods is
 * shared by every household and paid for once; a box with anything of the
 * family's own is theirs. The model hears foods only — never a child.
 *
 * Who may: anybody the household's `lunch` grant lets see every plan. Premium,
 * checked here and not only on the phone; a new picture is one of the
 * household's monthly AI calls (foundation ADR-0015), a cached one is free.
 *
 * 120 seconds and 512 MiB: an image takes far longer than a JSON answer, and
 * is held in memory to upload (BE-19).
 */
export const lunchPhoto = onCall(
  { timeoutSeconds: 120, memory: '512MiB' },
  async (request): Promise<LunchPhotoResult> => {
    const uid = requireUid(request.auth);
    const input = parseInput(lunchPhotoInput, request.data);
    const store = db();
    const caller = await photoCallerIn(store, input.householdId, uid);

    const entitlement = await entitlementRef(store, input.householdId).get();
    if (tierFrom(entitlement.data(), new Date()) !== 'premium') {
      throw premiumRequired('lunchPhoto');
    }

    const combination = combinationOf(await readBox(store, input));
    if (combination === null) throw refuseLunchPhoto('emptyBox');
    const place = photoPlace(store, input.householdId, combination);
    const state = await claimPhoto(store, place, new Date());
    if (state.status !== 'claimed') return state;

    let callsLeft: number;
    try {
      const result = await runImageCall(await imageRuntime(store), {
        feature: 'lunchPhoto',
        householdId: input.householdId,
        timeZone: caller.timeZone,
        uid,
        request: {
          prompt: promptFor(combination.foods),
          aspectRatio: '4:3',
          labels: { feature: 'lunchPhoto' },
        },
      });
      await objectStore().save(place.path, result.value.bytes, 'image/jpeg', PHOTO_CACHE_CONTROL);
      await markReady(store, place, result.value.modelVersion);
      callsLeft = result.callsLeft;
    } catch (error) {
      await releaseClaim(store, place);
      throw error;
    }

    // Never a food or a name (ENG-22).
    logger.info('lunch photo made', {
      householdId: input.householdId,
      scope: combination.scope,
      foods: combination.foods.length,
      callsLeft,
    });
    return { status: 'ready', path: place.path };
  },
);

/** The child's box that day; empty on a weekend or with no plan. */
async function readBox(store: Firestore, input: LunchPhotoInput): Promise<LunchBox> {
  const weekday = isoWeekday(input.date);
  if (weekday > 5) return {};
  const planId = `${input.childId}_${weekKeyOf(mondayOf(input.date))}`;
  const snapshot = await householdRef(store, input.householdId)
    .collection(LUNCH_PLANS)
    .doc(planId)
    .get();
  const plan = planFrom(snapshot.data());
  return plan === null || plan.childId !== input.childId ? {} : boxOn(plan, weekday);
}
