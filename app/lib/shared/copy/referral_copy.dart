import '../failure/app_failure.dart';

/// Every word *give a month, get a month* says (`FE-19`, subscriptions
/// ADR-0002) — beside `AppCopy` rather than inside it, like the other
/// features' words. `AppCopy.failure` reaches [problem] through one line.
abstract final class ReferralCopy {
  static const title = 'Give a month, get a month';

  // ---- the way in, from the household, the paywall and the invite step ----
  static const openFromHousehold = 'Give a month, get a month';
  static const openFromHouseholdBody =
      'Share NestPrep with another family and you both get premium free';
  static const mentionBody =
      'Know another family who’d love this? Share your code and you both get '
      'a month of premium, free.';

  // ---- the hero ----
  static const heroTitle = 'Share the calm';
  static const heroBody =
      'Give your code to another family. Once they’ve settled in together, '
      'both households get a month of premium — on us.';

  // ---- your code ----
  static const yourCode = 'Your family’s code';
  static const preparingCode = 'Making your code…';
  static const share = 'Share code';
  static const copy = 'Copy code';
  static const copied = 'Copied';
  static const shareUnavailable =
      'Sharing is not available on this phone. Copy the code and send it '
      'however you like.';
  static const shareSubject = 'A month of NestPrep, on us';
  static String shareMessage({required String code, Uri? appLink}) =>
      'We plan the week’s lunches, lists and school runs with NestPrep. Set '
      'up your household, enter our code $code in your first week, and we '
      'both get a month of premium free.'
      '${appLink == null ? '' : '\n\n$appLink'}';

  // ---- the months ----
  static const monthsTitle = 'Your free months';
  static String monthsThisYear(int earned, int cap) =>
      '$earned of $cap free months earned this year';
  static String runningUntil(String date) => 'A free month runs until $date.';
  static String waiting(int months) => months == 1
      ? 'One free month is waiting. It starts when your paid plan ends.'
      : '$months free months are waiting. They start when your paid plan ends.';
  static const noMonthsYet = 'None yet — each family who joins adds one.';
  static const capReached =
      'You’ve reached this year’s free months. Families who join still get '
      'theirs.';

  // ---- entering somebody else's code ----
  static const redeemTitle = 'Joined because of another family?';
  static String redeemBody(String date) =>
      'Enter their code by $date and you’ll both get a month once your '
      'household is set up.';
  static const redeemLabel = 'Their code';
  static const redeemHint = 'Eight letters and numbers';
  static const redeemAction = 'Use this code';
  static String redeemed(String date) =>
      'Code accepted. Once a second grown-up opens NestPrep in your household '
      '— or you choose premium — by $date, you both get your month.';

  // ---- how it works ----
  static const howTitle = 'How it works';
  static const howShare = 'Share your code with another family.';
  static const howJoin =
      'They set up their household and enter it in their first week.';
  static const howReward =
      'When two grown-ups there use NestPrep, or they choose premium, you both '
      'get a month.';
  static const howFinePrint =
      'Up to six free months a year. A month waits until any paid plan '
      'ends, so none is wasted.';

  // ---- the history ----
  static const historyTitle = 'Your referrals';
  static const historyEmpty =
      'No referrals yet. Share your code and they’ll show up here.';
  static const lineReferrer = 'A family joined with your code';
  static const lineReferred = 'You joined with another family’s code';
  static String linePending(String date) => 'Settling in · until $date';
  static String lineQualified(String date) => 'You both got a month · $date';
  static String lineCapped(String date) =>
      'They got their month; you’d reached this year’s · $date';
  static const lineExpired = 'Didn’t finish setting up in time';
  static const tagPending = 'Waiting';
  static const tagMonth = '+1 month';
  static const tagCapped = 'Limit reached';
  static const tagExpired = 'Expired';

  static String problem(ReferralProblem problem) => switch (problem) {
    ReferralProblem.referralsOff =>
      'Referrals are paused for now. Please try again later.',
    ReferralProblem.onlyFamilyCanRefer =>
      'Only a parent in the household can share or enter a referral code.',
    ReferralProblem.referralCodeNotFound =>
      'That code isn’t one we know. Check the letters and try again.',
    ReferralProblem.ownReferralCode =>
      'That code is from your own household — share it with another family.',
    ReferralProblem.alreadyRedeemed =>
      'Your household has already used a code.',
    ReferralProblem.tooLateToRedeem =>
      'Codes can only be used in a household’s first seven days.',
    ReferralProblem.tooManyRedemptions =>
      'That code has been used a lot today. Please try again tomorrow.',
  };
}
