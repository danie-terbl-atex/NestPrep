import type { TargetLanguage } from './languages';
import type { TranslationOutcome, Translator } from './translator';

/**
 * The translator under the emulator (home-care ADR-0006): it marks each text
 * with its language — `[zu] Open a window` — so a test can see a translation
 * happened and which, and no local run ever reaches Google or bills.
 */
export class EmulatorTranslator implements Translator {
  readonly engine = 'emulator';

  translate(texts: readonly string[], target: TargetLanguage): Promise<TranslationOutcome> {
    return Promise.resolve({
      kind: 'translated',
      texts: texts.map((text) => `[${target}] ${text}`),
    });
  }
}
