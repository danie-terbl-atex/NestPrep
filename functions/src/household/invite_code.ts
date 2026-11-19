import { randomInt } from 'node:crypto';

import type { RateLimitRule } from '../shared/rate_limit';
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

/** How often somebody not yet signed in may ask what a code offers (household ADR-0011). */
export const INVITE_PREVIEW_PER_ADDRESS: RateLimitRule = {
  name: 'previewInvite:address',
  limit: 20,
  windowSeconds: 10 * 60,
};
export const INVITE_PREVIEW_OVERALL: RateLimitRule = {
  name: 'previewInvite:all',
  limit: 1000,
  windowSeconds: 60 * 60,
};
