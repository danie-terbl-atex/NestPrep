import { HttpsError, type FunctionsErrorCode } from 'firebase-functions/v2/https';

/**
 * Every way a referrals call can refuse (subscriptions ADR-0002), on the same
 * contract as the household and subscriptions refusals (`BE-04`): a `reason`
 * the client maps to a sentence. `referral_contract_test.dart` reads this
 * block. None of these messages reaches a person.
 */
export const REFERRAL_REFUSALS = {
  notAMember: ['permission-denied', 'You are not in this household.'],
  householdNotFound: ['not-found', 'That household no longer exists.'],
  // Switched off in `appConfig/flags` (foundation ADR-0014).
  referralsOff: ['failed-precondition', 'Referrals are switched off.'],
  // Like buying, referring is the family's: not a helper's, carer's or kid's.
  onlyFamilyCanRefer: ['permission-denied', 'Only a parent can do that.'],
  referralCodeNotFound: ['not-found', 'That is not a NestPrep referral code.'],
  // The household's own code, or one from a household somebody here is in.
  ownReferralCode: ['failed-precondition', 'That code is from your own household.'],
  alreadyRedeemed: ['already-exists', 'This household has already used a code.'],
  tooLateToRedeem: ['failed-precondition', 'A code has to be used in the first seven days.'],
  tooManyRedemptions: ['resource-exhausted', 'That code has been used a lot today.'],
} as const satisfies Record<string, readonly [FunctionsErrorCode, string]>;

export type ReferralRefusal = keyof typeof REFERRAL_REFUSALS;

/** The one place a referrals refusal becomes the error the client receives. */
export function refuseReferral(reason: ReferralRefusal): HttpsError {
  const [code, message] = REFERRAL_REFUSALS[reason];
  return new HttpsError(code, message, { reason });
}
