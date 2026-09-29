import { refuseLetter } from './errors';
import { MAX_LETTER_BYTES, type LetterType } from './schemas';

/** The first bytes each accepted kind of file starts with. */
const SIGNATURES: Record<LetterType, readonly number[]> = {
  'image/jpeg': [0xff, 0xd8, 0xff],
  'image/png': [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a],
  'application/pdf': [0x25, 0x50, 0x44, 0x46, 0x2d], // %PDF-
};

const BASE64 = /^[A-Za-z0-9+/]+={0,2}$/;

/**
 * The letter's bytes, checked before a single token is spent (calendar
 * ADR-0005): valid base64, no larger than a letter needs to be, and really
 * the kind of file it claims — a PDF that is not one is refused here rather
 * than billed as a model call that reads nothing. Returns the base64 as it
 * came, which is what the model is handed.
 */
export function checkedLetter(mimeType: LetterType, data: string): string {
  if (!BASE64.test(data) || data.length % 4 !== 0) throw refuseLetter('letterNotSupported');
  const bytes = Buffer.from(data, 'base64');
  if (bytes.length > MAX_LETTER_BYTES) throw refuseLetter('letterTooLarge');
  const signature = SIGNATURES[mimeType];
  const matches = signature.every((byte, index) => bytes[index] === byte);
  if (!matches) throw refuseLetter('letterNotSupported');
  return data;
}
