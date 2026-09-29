import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/nullable_timestamp_converter.dart';
import 'billing_store.dart';
import 'entitlement_status.dart';
import 'subscription_plan.dart';

part 'entitlement.freezed.dart';
part 'entitlement.g.dart';

/// What the household may do, at `households/{id}/entitlement/current`
/// (subscriptions ADR-0001). Only a Function writes it, after a store has
/// vouched for a purchase; everybody in the household reads it. A household
/// with no document is on the free tier — [Entitlement.free].
@freezed
abstract class Entitlement with _$Entitlement {
  const factory Entitlement({
    /// Premium until this instant, or none. The rules compare it with the
    /// request's time, so premium ends at it with nothing having to notice.
    @NullableTimestampConverter() DateTime? premiumUntil,

    /// A status this build has never heard of reads as none: the date above
    /// still says whether there is premium (`BE-10`).
    @JsonKey(unknownEnumValue: EntitlementStatus.none)
    @Default(EntitlementStatus.none)
    EntitlementStatus status,
    @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
    SubscriptionPlan? plan,
    @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
    BillingStore? store,

    /// Null when the store has not said.
    bool? willRenew,

    /// Who bought it — the one person whose store account can change it.
    String? managedByMemberId,

    /// A sandbox or licence-tester purchase.
    @Default(false) bool isTest,

    /// Premium from the stores alone, before any month the household was
    /// given (subscriptions ADR-0002).
    @NullableTimestampConverter() DateTime? storeUntil,

    /// Until when given months cover the household, or null.
    @NullableTimestampConverter() DateTime? referralUntil,

    /// Given days that wait behind paid time and start when it ends.
    @Default(0) int referralDaysWaiting,
  }) = _Entitlement;

  const Entitlement._();

  factory Entitlement.fromJson(Map<String, Object?> json) =>
      _$EntitlementFromJson(json);

  static const free = Entitlement();

  bool isPremiumAt(DateTime now) {
    final until = premiumUntil;
    return until != null && until.isAfter(now);
  }

  /// Bought once and not premium now — lapsed, on hold, refunded. The plan
  /// screen says why, and that nothing the family made has gone.
  bool hasLapsedAt(DateTime now) =>
      status != EntitlementStatus.none && !isPremiumAt(now);

  /// The store said it renews on its own at [premiumUntil]; otherwise that
  /// date is when what was paid for ends.
  bool get isRenewing => willRenew == true;

  /// Premium now that no store sold — a month from a referral
  /// (subscriptions ADR-0002).
  bool isGivenOnlyAt(DateTime now) =>
      status == EntitlementStatus.none && isPremiumAt(now);

  /// Whole months waiting behind paid time, rounded up so a part is said.
  int get referralMonthsWaiting => (referralDaysWaiting + 29) ~/ 30;
}
