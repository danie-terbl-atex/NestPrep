import type { DocumentReference, Firestore } from 'firebase-admin/firestore';

import { tierFrom } from '../ai/usage_rules';
import { boxOn, combinationOf } from '../lunch_photos/combination';
import { photoPlace, photoStateOf } from '../lunch_photos/photo_documents';
import { readLunchPicks, type LunchPicksToday } from '../notifications/digest_reads';
import { isoWeekday } from '../school_letter/plain_date';
import { mondayOf, weekKeyOf } from '../plan_week/iso_week';
import { LUNCH_PLANS, planFrom } from '../plan_week/week_documents';
import { entitlementRef } from '../subscriptions/subscription_documents';

/** A box's picture as the frame names it, and the Storage object behind the name. */
export interface FrameLunchPhoto {
  readonly id: string;
  readonly path: string;
}

export interface FrameLunch {
  readonly lunch: readonly LunchPicksToday[];
  /** childId → the ready picture of that child's box today. */
  readonly lunchPhotos: Readonly<Record<string, FrameLunchPhoto>>;
}

/**
 * Today's boxes and, for a premium household, the picture the app made of
 * each (photo-frames ADR-0009, lunch-box ADR-0015). A frame never makes one:
 * a box nobody has pictured yet has none, so the wall never spends one of the
 * household's AI calls. The id is the combination's cache key, which names
 * foods and nothing else.
 */
export async function readFrameLunch(
  store: Firestore,
  home: DocumentReference,
  today: string,
  premium: Promise<boolean> = readFramePremium(store, home),
): Promise<FrameLunch> {
  const [lunch, isPremium] = await Promise.all([readLunchPicks(home, today), premium]);
  if (lunch.length === 0 || !isPremium) {
    return { lunch, lunchPhotos: {} };
  }

  const week = weekKeyOf(mondayOf(today));
  const plans = await store.getAll(
    ...lunch.map(({ childId }) => home.collection(LUNCH_PLANS).doc(`${childId}_${week}`)),
  );
  const boxes = plans.flatMap((snapshot, index) => {
    const childId = lunch[index]?.childId;
    const plan = planFrom(snapshot.data());
    if (plan === null || plan.childId !== childId) return [];
    const combination = combinationOf(boxOn(plan, isoWeekday(today)));
    if (combination === null) return [];
    return [{ childId, id: combination.key, place: photoPlace(store, home.id, combination) }];
  });
  if (boxes.length === 0) return { lunch, lunchPhotos: {} };

  const stored = await store.getAll(...boxes.map(({ place }) => place.ref));
  const now = new Date();
  const lunchPhotos = Object.fromEntries(
    boxes.flatMap(({ childId, id }, index) => {
      const state = photoStateOf(stored[index]?.data(), now);
      return state.status === 'ready' ? [[childId, { id, path: state.path }] as const] : [];
    }),
  );
  return { lunch, lunchPhotos };
}

export async function readFramePremium(
  store: Firestore,
  home: DocumentReference,
): Promise<boolean> {
  const entitlement = await entitlementRef(store, home.id).get();
  return tierFrom(entitlement.data(), new Date()) === 'premium';
}
