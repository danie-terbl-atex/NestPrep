import { hash } from 'node:crypto';

/**
 * The id a translation is cached under (home-care ADR-0006):
 * `{sha256 of the text, hex}_{language}`. The app computes the same id to read
 * the cache before it asks, so the two must agree to the byte —
 * `translation.test.ts` here and `helper_language_test.dart` there
 * hold the same vectors. The text is hashed exactly as sent: trimming happens
 * before, and a text that differs by a letter is a new text.
 */
export function translationId(text: string, language: string): string {
  return `${hash('sha256', text, 'hex')}_${language}`;
}
