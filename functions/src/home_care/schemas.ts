import { z } from 'zod';

import { TARGET_LANGUAGES } from './languages';

/** The most texts one call carries: a job's steps and its safety, with room to spare. */
export const MAX_TEXTS_PER_CALL = 60;

/** The longest text translated — a step, an item or a safety line is far shorter. */
export const MAX_TEXT_LENGTH = 500;

/**
 * Translating a job's or a routine's words (home-care ADR-0006), parsed at the
 * edge and never cast (ENG-09, BE-03). Every text is trimmed and non-empty; a
 * repeated one is asked for once.
 */
export const translateHomeCareTextsInput = z.object({
  householdId: z.string().trim().min(1).max(64),
  language: z.enum(TARGET_LANGUAGES),
  texts: z
    .array(z.string().trim().min(1).max(MAX_TEXT_LENGTH))
    .min(1)
    .max(MAX_TEXTS_PER_CALL)
    .transform((texts) => [...new Set(texts)]),
});
export type TranslateHomeCareTextsInput = z.infer<typeof translateHomeCareTextsInput>;
