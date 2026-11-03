import type { PremiumGrant } from '../subscriptions/premium_composition';
import type { StoredCode, StoredVoucher } from './voucher_documents';

const DAY_MS = 24 * 60 * 60 * 1000;

export const CLAIM_GRACE_MS = 30 * DAY_MS;
export const CODE_GRANT_YEAR_MS = 365 * DAY_MS;
export const CODE_TIME_ZONE = 'Africa/Johannesburg';

const sastDay = new Intl.DateTimeFormat('en-CA', {
  timeZone: CODE_TIME_ZONE,
  year: 'numeric',
  month: '2-digit',
  day: '2-digit',
});

export function sastDate(instant: Date): string {
  return sastDay.format(instant);
}

export type RedeemRefusal =
  | { readonly error: 'codePaused' }
  | { readonly error: 'codeNotStarted'; readonly startsOn: string }
  | { readonly error: 'codeExpired'; readonly endedOn: string }
  | { readonly error: 'codeUsedUp' };

export function redeemRefusalOf(code: StoredCode, now: Date): RedeemRefusal | null {
  if (code.status === 'paused') return { error: 'codePaused' };
  if (now.getTime() < code.validFrom.getTime()) {
    return { error: 'codeNotStarted', startsOn: sastDate(code.validFrom) };
  }
  if (code.validUntil !== null && now.getTime() > code.validUntil.getTime()) {
    return { error: 'codeExpired', endedOn: sastDate(code.validUntil) };
  }
  if (isUsedUp(code)) return { error: 'codeUsedUp' };
  return null;
}

export function isUsedUp(code: StoredCode): boolean {
  return code.maxClaims !== null && code.claimCount >= code.maxClaims;
}

export function claimByOf(code: StoredCode): Date | null {
  return code.validUntil === null ? null : new Date(code.validUntil.getTime() + CLAIM_GRACE_MS);
}

export function isPastClaimBy(voucher: Pick<StoredVoucher, 'claimBy'>, now: Date): boolean {
  return voucher.claimBy !== null && now.getTime() > voucher.claimBy.getTime();
}

export type CodeWindowRefusal = 'codePaused' | 'codeExpired';

export function claimWindowRefusalOf(
  code: StoredCode | null,
  voucher: StoredVoucher,
  now: Date,
): CodeWindowRefusal | null {
  if (code === null || code.status === 'archived') return 'codeExpired';
  if (code.status === 'paused') return 'codePaused';
  if (now.getTime() < code.validFrom.getTime()) return 'codePaused';
  const claimBy = claimByOf(code);
  if (claimBy !== null && now.getTime() > claimBy.getTime()) return 'codeExpired';
  if (isPastClaimBy(voucher, now)) return 'codeExpired';
  return null;
}

export function usedCodeWithinYear(grants: readonly PremiumGrant[], now: Date): boolean {
  const since = now.getTime() - CODE_GRANT_YEAR_MS;
  return grants.some((grant) => grant.source === 'code' && grant.grantedAt.getTime() > since);
}

export function isNewToPremium(
  grants: readonly PremiumGrant[],
  hasStorePurchase: boolean,
): boolean {
  return grants.length === 0 && !hasStorePurchase;
}
