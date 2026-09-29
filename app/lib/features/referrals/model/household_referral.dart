import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/nullable_timestamp_converter.dart';

part 'household_referral.freezed.dart';
part 'household_referral.g.dart';

/// The household's own side of *give a month, get a month*, at
/// `households/{id}/referral/current` (subscriptions ADR-0002): its code, and
/// until when it may still enter another family's. Written only by
/// Functions; a household with no document has no code yet —
/// [HouseholdReferral.none].
@freezed
abstract class HouseholdReferral with _$HouseholdReferral {
  const factory HouseholdReferral({
    /// Null until `ensureReferralCode` has made it.
    String? code,

    /// The end of the household's first seven days, or null when its age is
    /// unknown — then no code can be entered.
    @NullableTimestampConverter() DateTime? redeemBy,

    /// Whether this household has already entered somebody else's code.
    @Default(false) bool hasRedeemed,

    /// The most referral months a household gets in a year — the server's
    /// rule, said by the server.
    @Default(0) int yearlyRewardCap,
  }) = _HouseholdReferral;

  const HouseholdReferral._();

  factory HouseholdReferral.fromJson(Map<String, Object?> json) =>
      _$HouseholdReferralFromJson(json);

  static const none = HouseholdReferral();

  /// Whether the screen offers to enter a code. The server decides for real;
  /// this only avoids offering what it would refuse (`FE-04`).
  bool canRedeemAt(DateTime now) {
    final deadline = redeemBy;
    return !hasRedeemed && deadline != null && now.isBefore(deadline);
  }
}
