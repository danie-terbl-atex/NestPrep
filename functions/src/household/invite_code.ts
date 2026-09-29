import { randomInt } from 'node:crypto';

import { generateReadableCode, isReadableCode } from '../shared/readable_code';

const CODE_LENGTH = 8;

/** Seven days, in milliseconds (household ADR-0002). */
export const INVITE_LIFETIME_MS = 7 * 24 * 60 * 60 * 1000;

export function generateInviteCode(random: (max: number) => number = randomInt): string {
  return generateReadableCode(CODE_LENGTH, random);
}

/** Whether a string could be one of our codes at all, before we go looking. */
export function looksLikeInviteCode(code: string): boolean {
  return isReadableCode(code, CODE_LENGTH);
}
