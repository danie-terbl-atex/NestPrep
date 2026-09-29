import { randomInt } from 'node:crypto';

/**
 * No 0/O, no 1/I/L: a code is read off one screen and typed into another, and
 * every pair a person confuses is a support conversation (household ADR-0002).
 * Invites and kid pairing codes draw from the same letters, so a person only
 * ever learns one set (accounts ADR-0003).
 */
export const READABLE_ALPHABET = '23456789ABCDEFGHJKMNPQRSTUVWXYZ';

export function generateReadableCode(
  length: number,
  random: (max: number) => number = randomInt,
): string {
  const characters: string[] = [];
  for (let index = 0; index < length; index += 1) {
    characters.push(READABLE_ALPHABET.charAt(random(READABLE_ALPHABET.length)));
  }
  return characters.join('');
}

/** Whether a string could be a code of this length at all, before anybody looks it up. */
export function isReadableCode(code: string, length: number): boolean {
  if (code.length !== length) return false;
  for (let index = 0; index < code.length; index += 1) {
    if (!READABLE_ALPHABET.includes(code.charAt(index))) return false;
  }
  return true;
}
