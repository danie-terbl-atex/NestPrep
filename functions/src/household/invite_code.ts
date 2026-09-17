import { randomInt } from 'node:crypto';

/**
 * No 0/O, no 1/I/L: a code is read off one phone and typed into another, and
 * every pair a person confuses is a support conversation (household ADR-0002).
 */
const ALPHABET = '23456789ABCDEFGHJKMNPQRSTUVWXYZ';
const CODE_LENGTH = 8;

/** Seven days, in milliseconds (household ADR-0002). */
export const INVITE_LIFETIME_MS = 7 * 24 * 60 * 60 * 1000;

export function generateInviteCode(random: (max: number) => number = randomInt): string {
  const characters: string[] = [];
  for (let index = 0; index < CODE_LENGTH; index += 1) {
    characters.push(ALPHABET.charAt(random(ALPHABET.length)));
  }
  return characters.join('');
}

/** Whether a string could be one of our codes at all, before we go looking. */
export function looksLikeInviteCode(code: string): boolean {
  if (code.length !== CODE_LENGTH) return false;
  for (let index = 0; index < code.length; index += 1) {
    if (!ALPHABET.includes(code.charAt(index))) return false;
  }
  return true;
}
