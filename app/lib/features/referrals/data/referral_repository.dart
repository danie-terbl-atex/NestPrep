import '../model/household_referral.dart';
import '../model/premium_grant.dart';
import '../model/referral_line.dart';

/// Where the referral screen reads from (subscriptions ADR-0002). Every one
/// of these is written by Functions alone and read by family alone; the rules
/// refuse a helper, carer or kid, whose listener fails rather than shows.
abstract interface class ReferralRepository {
  /// The household's code and whether it may still enter one — `none` when
  /// no code has been made yet.
  Stream<HouseholdReferral> watchReferral(String householdId);

  /// Every referral the household took part in, newest first.
  Stream<List<ReferralLine>> watchHistory(String householdId);

  /// The months it was given, newest first.
  Stream<List<PremiumGrant>> watchGrants(String householdId);

  /// More than the yearly limit, a few times over — a bounded read (`FE-11`).
  static const lineLimit = 50;
}
