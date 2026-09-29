import { FieldValue, type Firestore } from 'firebase-admin/firestore';

import { translationRef } from './home_care_refs';
import type { TargetLanguage } from './languages';
import { translationId } from './translation_id';

/** English text → its translation. A record, not a `Map`, for the atomic-writes check. */
export type Translations = Record<string, string>;

/**
 * The household's translations, each made once (home-care ADR-0006): read
 * before anything is paid for, written after, and never by a client.
 */
export async function readCachedTranslations(
  store: Firestore,
  householdId: string,
  texts: readonly string[],
  language: TargetLanguage,
): Promise<Translations> {
  const refs = texts.map((text) =>
    translationRef(store, householdId, translationId(text, language)),
  );
  const snapshots = await store.getAll(...refs);
  const found: Translations = {};
  snapshots.forEach((snapshot, index) => {
    const translated: unknown = snapshot.get('text');
    const text = texts[index];
    if (text !== undefined && typeof translated === 'string') found[text] = translated;
  });
  return found;
}

/** Stores what was just translated, in one batch, so the next ask is free. */
export async function cacheTranslations(
  store: Firestore,
  householdId: string,
  language: TargetLanguage,
  translated: Readonly<Translations>,
  engine: string,
): Promise<void> {
  const batch = store.batch();
  for (const [text, translation] of Object.entries(translated)) {
    batch.set(translationRef(store, householdId, translationId(text, language)), {
      language,
      text: translation,
      engine,
      createdAt: FieldValue.serverTimestamp(),
    });
  }
  await batch.commit();
}
