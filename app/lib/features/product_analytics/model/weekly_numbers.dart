import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/nullable_timestamp_converter.dart';
import '../../../shared/recurrence/calendar_date_converter.dart';
import '../../../shared/time/calendar_date.dart';
import '../../subscriptions/model/premium_feature.dart';
import 'trigger_conversion.dart';

part 'weekly_numbers.freezed.dart';
part 'weekly_numbers.g.dart';

/// One week's beta numbers, at `analyticsWeeks/{week}` — counts only, written
/// by the nightly rollup and never by a client (product-analytics ADR-0001).
///
/// Every field name here is also written by
/// `functions/src/product_analytics/weekly_summary.ts`, and
/// `functions/test/unit/product_analytics_contract.test.ts` reads both files so
/// the two cannot drift. A count missing from an older document reads as zero
/// (`BE-10`).
@freezed
abstract class WeeklyNumbers with _$WeeklyNumbers {
  const factory WeeklyNumbers({
    /// The ISO week, `YYYY-Www` — also the document id.
    required String week,

    /// The Monday the week starts on.
    @CalendarDateConverter() required CalendarDate weekStart,

    /// The north star: families where two or more people used NestPrep.
    @Default(0) int activeFamilies,

    /// Families where anybody did — what [activeFamilies] is read against.
    @Default(0) int familiesSeen,
    @Default(0) int lunchPlansCreated,
    @Default(0) int familiesPlanningLunches,

    /// Families created this week: the invite cohort.
    @Default(0) int newFamilies,
    @Default(0) int newFamiliesInvitingAnAdult,

    /// False until every family in the cohort has had its first seven days.
    @Default(false) bool isInviteCohortComplete,

    /// Families shown the paywall at all this week (product-analytics
    /// ADR-0002) — what conversion is read against.
    @Default(0) int paywallFamilies,

    /// The same by trigger — the server's `CONVERSION_TRIGGERS`, which are
    /// `PremiumFeature`'s names. A family counts once for each it met.
    @Default(<String, int>{}) Map<String, int> paywallFamiliesByTrigger,
    @Default(0) int premiumConversions,
    @Default(<String, int>{}) Map<String, int> premiumConversionsByTrigger,

    /// Give a month, get a month (subscriptions ADR-0002): codes entered,
    /// referrals that became a family, and the free months that gave.
    @Default(0) int referralsRedeemed,
    @Default(0) int referralsQualified,
    @Default(0) int referralMonthsGiven,
    @NullableTimestampConverter() DateTime? computedAt,
  }) = _WeeklyNumbers;

  const WeeklyNumbers._();

  factory WeeklyNumbers.fromJson(Map<String, Object?> json) =>
      _$WeeklyNumbersFromJson(json);

  /// The invite rate as a whole percentage, or null when nobody new joined —
  /// a 0% there would read as a failure that never happened.
  int? get inviteRatePercent => newFamilies == 0
      ? null
      : (newFamiliesInvitingAnAdult * 100 / newFamilies).round();

  /// Conversion as a whole percentage of the families shown premium, or null
  /// when nobody was — never a 0% that never happened.
  int? get conversionRatePercent => paywallFamilies == 0
      ? null
      : (premiumConversions * 100 / paywallFamilies).round();

  /// Conversion by the feature that opened the paywall, for every trigger
  /// somebody met or bought through this week, in the order the triggers are
  /// declared.
  List<TriggerConversion> get byTrigger => [
    for (final feature in PremiumFeature.values)
      if ((paywallFamiliesByTrigger[feature.name] ?? 0) > 0 ||
          (premiumConversionsByTrigger[feature.name] ?? 0) > 0)
        TriggerConversion(
          feature: feature,
          families: paywallFamiliesByTrigger[feature.name] ?? 0,
          conversions: premiumConversionsByTrigger[feature.name] ?? 0,
        ),
  ];

  bool get hasPremiumActivity =>
      paywallFamilies > 0 ||
      premiumConversions > 0 ||
      referralsRedeemed > 0 ||
      referralsQualified > 0;
}
