import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/nullable_timestamp_converter.dart';
import 'referral_reward.dart';
import 'referral_side.dart';
import 'referral_status.dart';

part 'referral_line.freezed.dart';
part 'referral_line.g.dart';

/// One referral this household took part in, at
/// `households/{id}/referralHistory/{entryId}` (subscriptions ADR-0002).
/// Written only by Functions; it says nothing about the other household.
@freezed
abstract class ReferralLine with _$ReferralLine {
  const factory ReferralLine({
    @JsonKey(includeToJson: false) required String id,
    @JsonKey(unknownEnumValue: ReferralSide.referred)
    @Default(ReferralSide.referred)
    ReferralSide side,

    /// A status this build has never heard of reads as pending (`BE-10`).
    @JsonKey(unknownEnumValue: ReferralStatus.pending)
    @Default(ReferralStatus.pending)
    ReferralStatus status,
    @NullableTimestampConverter() DateTime? redeemedAt,

    /// The server's deadline for the new household to become a family.
    @NullableTimestampConverter() DateTime? qualifyBy,
    @NullableTimestampConverter() DateTime? qualifiedAt,
    @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
    ReferralReward? reward,
  }) = _ReferralLine;

  const ReferralLine._();

  factory ReferralLine.fromJson(Map<String, Object?> json) =>
      _$ReferralLineFromJson(json);

  /// The status as of [now]. The server marks a lapsed referral expired only
  /// when it next touches it; its own deadline, stored here, already says so.
  ReferralStatus statusAt(DateTime now) {
    final deadline = qualifyBy;
    return status == ReferralStatus.pending &&
            deadline != null &&
            now.isAfter(deadline)
        ? ReferralStatus.expired
        : status;
  }
}
