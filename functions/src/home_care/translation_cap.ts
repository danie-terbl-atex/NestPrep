/**
 * What a household may spend on new translations in a month (home-care
 * ADR-0006): characters sent to Google, counted before it is asked and given
 * back if it fails. A cached text costs nothing. Pure, so the arithmetic is
 * tested without an emulator.
 */
export const FREE_MONTHLY_CHARACTERS = 20_000;
export const PREMIUM_MONTHLY_CHARACTERS = 200_000;

/** The month a spend is counted in: the calendar month in UTC, `YYYY-MM`. */
export function monthKey(now: Date): string {
  const month = String(now.getUTCMonth() + 1).padStart(2, '0');
  return `${String(now.getUTCFullYear())}-${month}`;
}

export function monthlyAllowance(isPremium: boolean): number {
  return isPremium ? PREMIUM_MONTHLY_CHARACTERS : FREE_MONTHLY_CHARACTERS;
}

/**
 * Characters sent, counted in UTF-16 units — never fewer than Google bills,
 * so the cap errs on the side of the household's money.
 */
export function charactersOf(texts: readonly string[]): number {
  return texts.reduce((sum, text) => sum + text.length, 0);
}

/** The month's count after this spend, or null when it would pass the allowance. */
export function spendWithin(spent: unknown, wanted: number, allowance: number): number | null {
  const before = typeof spent === 'number' && Number.isFinite(spent) && spent > 0 ? spent : 0;
  const after = before + wanted;
  return after > allowance ? null : after;
}

/** The count after a refund, never below nothing. */
export function refunded(spent: unknown, amount: number): number {
  const before = typeof spent === 'number' && Number.isFinite(spent) ? spent : 0;
  return Math.max(0, before - amount);
}
