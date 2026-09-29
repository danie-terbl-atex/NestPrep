import type { CollectionReference, DocumentReference, Firestore } from 'firebase-admin/firestore';

import { HOUSEHOLDS } from '../household/documents';

/** Home care's collections the Functions touch (home-care ADR-0005, ADR-0006). */
export const HOME_CARE_PRODUCTS = 'homeCareProducts';
export const HOME_CARE_TRANSLATIONS = 'homeCareTranslations';
export const HOME_CARE_TRANSLATION_USAGE = 'homeCareTranslationUsage';
export const GROCERY_ITEMS = 'groceryItems';

export function translationRef(
  store: Firestore,
  householdId: string,
  id: string,
): DocumentReference {
  return store.collection(HOUSEHOLDS).doc(householdId).collection(HOME_CARE_TRANSLATIONS).doc(id);
}

export function usageRef(store: Firestore, householdId: string, month: string): DocumentReference {
  return store
    .collection(HOUSEHOLDS)
    .doc(householdId)
    .collection(HOME_CARE_TRANSLATION_USAGE)
    .doc(month);
}

export function groceryItems(store: Firestore, householdId: string): CollectionReference {
  return store.collection(HOUSEHOLDS).doc(householdId).collection(GROCERY_ITEMS);
}
