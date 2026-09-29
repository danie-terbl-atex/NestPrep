import { z } from 'zod';

/** The kinds of file a letter may be (calendar ADR-0005). */
export const LETTER_TYPES = ['image/jpeg', 'image/png', 'application/pdf'] as const;
export type LetterType = (typeof LETTER_TYPES)[number];

/**
 * The largest letter read, in bytes. A photo leaves the phone compressed to a
 * few hundred kilobytes; a PDF newsletter of a few pages fits. Base64 makes it
 * about 5.3 MB on the wire, inside a callable's 10 MB.
 */
export const MAX_LETTER_BYTES = 4 * 1024 * 1024;

/**
 * What the edge accepts at all: twice the letter limit in base64. Between the
 * two, the body parses and the letter is refused as `letterTooLarge`, which
 * the app can put in words; past it, the body is simply a bad request.
 */
const MAX_BASE64_LENGTH = Math.ceil(MAX_LETTER_BYTES / 3) * 4 * 2;

/**
 * Reading a school letter, parsed at the edge (ENG-09, BE-03). The bytes
 * travel in the call and are never stored: nothing about the letter outlives
 * the request.
 */
export const readSchoolLetterInput = z.object({
  householdId: z.string().trim().min(1).max(64),
  mimeType: z.enum(LETTER_TYPES),
  data: z.string().min(1).max(MAX_BASE64_LENGTH),
});
export type ReadSchoolLetterInput = z.infer<typeof readSchoolLetterInput>;
