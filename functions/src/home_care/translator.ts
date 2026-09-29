import type { TargetLanguage } from './languages';

/**
 * What a translator answered for a batch of English texts, in the order asked
 * (home-care ADR-0006). A failure is a value, not a throw, so the callable can
 * refund the month's claim before it refuses (BE-06, BE-09).
 */
export type TranslationOutcome =
  | { readonly kind: 'translated'; readonly texts: readonly string[] }
  | { readonly kind: 'unsupported' }
  | { readonly kind: 'unavailable'; readonly reason: string };

/** The one door to a translation service, so every test runs against a fake. */
export interface Translator {
  /** The engine's name, stored on each cached translation. */
  readonly engine: string;
  translate(texts: readonly string[], target: TargetLanguage): Promise<TranslationOutcome>;
}
