import { isChildRole } from '../product_analytics/metric_definitions';

/**
 * What a referral is worth and what earns it — every number and rule of
 * *give a month, get a month* in one place (subscriptions ADR-0002). The
 * ledger records facts; these judge them.
 */

/** "A month" of premium: thirty days of instants, the same for everybody (`ENG-21`). */
export const REFERRAL_REWARD_DAYS = 30;

const DAY_MS = 24 * 60 * 60 * 1000;

/** A new household may enter somebody's code within its first seven days. */
export const REDEEM_WINDOW_MS = 7 * DAY_MS;

/** A redeemed referral has fourteen days to become a real family. */
export const QUALIFY_WINDOW_MS = 14 * DAY_MS;

/** At most six referral months reach one household in any rolling year. */
export const YEARLY_REWARD_CAP = 6;
export const REWARD_YEAR_MS = 365 * DAY_MS;

/** At most five households may redeem one household's code in any 24 hours. */
export const REDEMPTIONS_PER_DAY = 5;
export const REDEMPTION_DAY_MS = DAY_MS;

/** How many distinct adults must use the new household for it to be a family. */
export const ADULTS_FOR_A_FAMILY = 2;

export const REFERRAL_CODE_LENGTH = 8;

/** Whether a household made at [createdAt] may still enter a code at [now]. */
export function mayStillRedeem(createdAt: Date | null, now: Date): boolean {
  if (createdAt === null) return false;
  const age = now.getTime() - createdAt.getTime();
  return age >= 0 && age <= REDEEM_WINDOW_MS;
}

export function redeemByOf(createdAt: Date | null): Date | null {
  return createdAt === null ? null : new Date(createdAt.getTime() + REDEEM_WINDOW_MS);
}

export function qualifyByOf(redeemedAt: Date): Date {
  return new Date(redeemedAt.getTime() + QUALIFY_WINDOW_MS);
}

export type Roles = Readonly<Record<string, string>>;

/**
 * Whether [uid] counts toward the new household being a family: an adult in
 * it (the analytics' own "not a child role") who is no member of the
 * household that referred it — so nobody qualifies a referral for their own
 * household by joining the new one.
 */
export function countsAsNewAdult(uid: string, referred: Roles, referrer: Roles): boolean {
  const role = referred[uid];
  return role !== undefined && !isChildRole(role) && referrer[uid] === undefined;
}

/** The adults who have used the new household since it redeemed, by the rule above. */
export function newAdultsSeen(
  activeUids: readonly string[],
  referred: Roles,
  referrer: Roles,
): string[] {
  return [...new Set(activeUids)].filter((uid) => countsAsNewAdult(uid, referred, referrer));
}

/** The redemptions of one code inside the last day, oldest first — at most the limit. */
export function redeemedWithinADay(times: readonly Date[], now: Date): Date[] {
  const since = now.getTime() - REDEMPTION_DAY_MS;
  return times
    .filter((at) => at.getTime() > since)
    .sort((a, b) => a.getTime() - b.getTime())
    .slice(-REDEMPTIONS_PER_DAY);
}

/** Whether the two households share anybody: a referral to yourself. */
export function sharesAMember(referred: Roles, referrer: Roles): boolean {
  return Object.keys(referred).some((uid) => referrer[uid] !== undefined);
}

/** Whether a household given referral months at [grantedAt] may be given another at [now]. */
export function isUnderYearlyCap(grantedAt: readonly Date[], now: Date): boolean {
  const since = now.getTime() - REWARD_YEAR_MS;
  return grantedAt.filter((at) => at.getTime() > since).length < YEARLY_REWARD_CAP;
}
