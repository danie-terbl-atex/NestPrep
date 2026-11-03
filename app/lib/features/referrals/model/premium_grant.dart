import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/instant_converter.dart';
import '../../../shared/firestore/nullable_timestamp_converter.dart';
import '../../subscriptions/model/grant_source.dart';

part 'premium_grant.freezed.dart';
part 'premium_grant.g.dart';

/// Days of premium a household was given rather than bought, at
/// `households/{id}/premiumGrants/{grantId}` (subscriptions ADR-0002) — a
/// referral's month, a frame order's months or a gift (ADR-0003, ADR-0004).
/// Written only by Functions. A grant waits until
/// nothing else covers the household, then runs its days.
@freezed
abstract class PremiumGrant with _$PremiumGrant {
  const factory PremiumGrant({
    @JsonKey(includeToJson: false) required String id,
    required int days,
    @InstantConverter() required DateTime grantedAt,

    /// When it began running, or null while it waits behind paid time.
    @NullableTimestampConverter() DateTime? startsAt,
    @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
    GrantSource? source,
  }) = _PremiumGrant;

  const PremiumGrant._();

  factory PremiumGrant.fromJson(Map<String, Object?> json) =>
      _$PremiumGrantFromJson(json);

  bool get isWaiting => startsAt == null;

  bool get isReferral => source == GrantSource.referral;

  DateTime? get endsAt => startsAt?.add(Duration(days: days));

  bool isRunningAt(DateTime now) {
    final start = startsAt;
    final end = endsAt;
    return start != null &&
        end != null &&
        !now.isBefore(start) &&
        now.isBefore(end);
  }
}
