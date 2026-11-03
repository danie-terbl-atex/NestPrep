import '../../features/subscriptions/model/grant_source.dart';
import '../../features/subscriptions/model/premium_length.dart';
import '../../features/subscriptions/model/premium_voucher.dart';
import '../../features/subscriptions/model/premium_voucher_kind.dart';
import '../failure/app_failure.dart';

/// Premium that came from somewhere other than a store: a frame order or a
/// gift (subscriptions ADR-0003, ADR-0004). App Review 3.1.1: nothing here
/// names a code, a code's label or a partner, or says where a gift is
/// redeemed. The 6-digit code is the email check's, not a Premium code.
abstract final class PremiumVoucherCopy {
  static String length(PremiumLength length) => switch (length) {
    PremiumMonths(count: 1) => '1 month',
    PremiumMonths(:final count) => '$count months',
    PremiumDays(count: 1) => '1 day',
    PremiumDays(:final count) => '$count days',
  };

  static String voucherTitle(PremiumVoucher voucher) => switch (voucher.kind) {
    PremiumVoucherKind.frame =>
      '${length(voucher.length)} of Premium from your frame order',
    PremiumVoucherKind.code =>
      '${length(voucher.length)} of Premium waiting for you',
  };

  static String sentTo(String emailMasked) => 'Sent to $emailMasked';
  static const testOrder = 'Test';

  // ---- the claim sheet ----
  static const sheetTitle = 'Premium waiting for you';
  static String intoOnly(String household) =>
      'Add it to $household and everyone there gets Premium.';
  static const chooseHousehold = 'Which household is it for?';
  static const chooseHouseholdBody =
      'Everyone in the household you choose gets Premium.';
  static const loadingHouseholds = 'Finding your households…';
  static String addTo(String household) => 'Add to $household';
  static String added(String household) => 'Added. $household has Premium now.';
  static String addedQueued(String household) =>
      'Added to $household. It starts when your current subscription period '
      'ends, so none of it is wasted.';
  static const noFamilyHousehold =
      'Premium is added by a parent. Ask a parent in your household to sign '
      'in with this email, or confirm it on their account.';
  static const nothingLeft = 'That’s everything that was waiting.';
  static const done = 'Done';
  static const notNow = 'Not now';

  // ---- ordered with a different email ----
  static const differentEmail = 'Ordered with a different email?';
  static const differentEmailBody =
      'Enter the email your Premium was sent to. We’ll email it a 6-digit '
      'code to show it’s yours.';
  static const emailLabel = 'Email';
  static const emailHint = 'you@example.com';
  static const badEmail = 'That doesn’t look like an email address.';
  static const sendCode = 'Send code';
  static String codeSent(String emailMasked) =>
      'We’ve sent a 6-digit code to $emailMasked. It works for 10 minutes.';
  static const codeLabel = '6-digit code';
  static const codeIncomplete = 'Enter the 6 digits from the email.';
  static const confirm = 'Confirm';
  static const sendNewCode = 'Send a new code';
  static String newCodeIn(int seconds) => seconds == 1
      ? 'You can send a new code in 1 second.'
      : 'You can send a new code in $seconds seconds.';
  static const useAnotherEmail = 'Use a different email';
  static String confirmed(String emailMasked) => 'Confirmed: $emailMasked.';
  static String nothingWaitingFor(String emailMasked) =>
      '$emailMasked is on your account now. Nothing is waiting for it yet; '
      'when Premium is, it shows up here.';
  static const lookingForPremium = 'Looking for your Premium…';

  // ---- plan & billing ----
  static const timeTitle = 'Your Premium time';
  static const paidPlan = 'Paid plan';
  static const freePremium = 'Free Premium';
  static String until(String date) => 'Until $date';
  static String sourceTitle(GrantSource source) => switch (source) {
    GrantSource.referral => 'From referrals',
    GrantSource.frame => 'From your frame order',
    GrantSource.code => 'Gifted Premium',
  };
  static String waiting(GrantSource source, PremiumLength waiting) => switch ((
    source,
    waiting,
  )) {
    (GrantSource.referral, PremiumMonths(count: 1)) => '1 free month waiting',
    (GrantSource.referral, PremiumMonths(:final count)) =>
      '$count free months waiting',
    _ => '${length(waiting)} waiting',
  };
  static const waitsForPaid =
      'Free time waits until your paid plan ends, so none of it is wasted.';
  static String waitingEntry(List<PremiumVoucher> vouchers) =>
      vouchers.length == 1
      ? voucherTitle(vouchers.single)
      : 'More than one is waiting. Add each to a household.';

  static String problem(PremiumVoucherFailure failure) =>
      switch (failure.problem) {
        PremiumVoucherProblem.voucherNotFound =>
          'That Premium is no longer waiting.',
        PremiumVoucherProblem.notYourVoucher =>
          'That Premium was sent to a different email. Confirm that email to '
              'add it.',
        PremiumVoucherProblem.voucherClaimed =>
          'That Premium has already been added to a household.',
        PremiumVoucherProblem.voucherVoid =>
          'That Premium was cancelled, so it can’t be added.',
        PremiumVoucherProblem.testVoucher =>
          'That Premium is from a test order, so it can’t be added.',
        PremiumVoucherProblem.codeUsedUp =>
          'This Premium has all been claimed, so there’s none left to add.',
        PremiumVoucherProblem.codeAlreadyUsed
            when failure.scope == VoucherRefusalScope.person =>
          'You’ve already added this Premium to a household.',
        PremiumVoucherProblem.codeAlreadyUsed =>
          'This household has already had this Premium. Choose another '
              'household.',
        PremiumVoucherProblem.codeNotEligible =>
          'This Premium is for households that are new to Premium.',
        PremiumVoucherProblem.codeYearlyLimit =>
          'This household has had gifted Premium in the last year, so it '
              'can’t take more yet.',
        PremiumVoucherProblem.codeExpired =>
          'This Premium has ended, so it can’t be added any more.',
        PremiumVoucherProblem.codePaused =>
          'This Premium isn’t available right now. Please try again later.',
        PremiumVoucherProblem.emailCodeWrong =>
          'That code doesn’t match. Check the email and try again.',
        PremiumVoucherProblem.emailCodeExpired =>
          'That code has expired. Send a new one.',
        PremiumVoucherProblem.emailCodeTooManyTries =>
          'Too many tries. Send a new code.',
        PremiumVoucherProblem.emailAlreadyVerified =>
          'That email is already on your account.',
        PremiumVoucherProblem.tooManyCodes =>
          'Too many codes sent. Please try again later.',
      };
}
