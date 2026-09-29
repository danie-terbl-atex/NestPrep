import 'household_referral.dart';
import 'premium_grant.dart';
import 'referral_line.dart';
import 'referral_side.dart';

/// Everything the referral screen shows, as its three listeners last saw it
/// (subscriptions ADR-0002) — the household's code, its referrals and the
/// months it was given. Holds nothing the listeners do not (`FE-07`).
final class ReferralOverview {
  const ReferralOverview({
    required this.referral,
    required this.lines,
    required this.grants,
  });

  final HouseholdReferral referral;

  /// Newest first.
  final List<ReferralLine> lines;

  /// Newest first.
  final List<PremiumGrant> grants;

  static const _year = Duration(days: 365);

  /// Months given in the last year — what the server's yearly limit counts.
  int monthsThisYear(DateTime now) => grants
      .where((grant) => grant.grantedAt.isAfter(now.subtract(_year)))
      .length;

  bool hasReachedCapAt(DateTime now) =>
      referral.yearlyRewardCap > 0 &&
      monthsThisYear(now) >= referral.yearlyRewardCap;

  /// The month running now, if one is.
  PremiumGrant? runningAt(DateTime now) =>
      grants.where((grant) => grant.isRunningAt(now)).firstOrNull;

  /// Months waiting behind paid time.
  int get monthsWaiting => grants.where((grant) => grant.isWaiting).length;

  /// The line for the code this household entered, if it entered one.
  ReferralLine? get joinedWith =>
      lines.where((line) => line.side == ReferralSide.referred).firstOrNull;
}
