// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weekly_numbers.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WeeklyNumbers _$WeeklyNumbersFromJson(Map<String, dynamic> json) =>
    _WeeklyNumbers(
      week: json['week'] as String,
      weekStart: const CalendarDateConverter().fromJson(json['weekStart']),
      activeFamilies: (json['activeFamilies'] as num?)?.toInt() ?? 0,
      familiesSeen: (json['familiesSeen'] as num?)?.toInt() ?? 0,
      lunchPlansCreated: (json['lunchPlansCreated'] as num?)?.toInt() ?? 0,
      familiesPlanningLunches:
          (json['familiesPlanningLunches'] as num?)?.toInt() ?? 0,
      newFamilies: (json['newFamilies'] as num?)?.toInt() ?? 0,
      newFamiliesInvitingAnAdult:
          (json['newFamiliesInvitingAnAdult'] as num?)?.toInt() ?? 0,
      isInviteCohortComplete: json['isInviteCohortComplete'] as bool? ?? false,
      paywallFamilies: (json['paywallFamilies'] as num?)?.toInt() ?? 0,
      paywallFamiliesByTrigger:
          (json['paywallFamiliesByTrigger'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toInt()),
          ) ??
          const <String, int>{},
      premiumConversions: (json['premiumConversions'] as num?)?.toInt() ?? 0,
      premiumConversionsByTrigger:
          (json['premiumConversionsByTrigger'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toInt()),
          ) ??
          const <String, int>{},
      referralsRedeemed: (json['referralsRedeemed'] as num?)?.toInt() ?? 0,
      referralsQualified: (json['referralsQualified'] as num?)?.toInt() ?? 0,
      referralMonthsGiven: (json['referralMonthsGiven'] as num?)?.toInt() ?? 0,
      computedAt: const NullableTimestampConverter().fromJson(
        json['computedAt'],
      ),
    );

Map<String, dynamic> _$WeeklyNumbersToJson(
  _WeeklyNumbers instance,
) => <String, dynamic>{
  'week': instance.week,
  'weekStart': const CalendarDateConverter().toJson(instance.weekStart),
  'activeFamilies': instance.activeFamilies,
  'familiesSeen': instance.familiesSeen,
  'lunchPlansCreated': instance.lunchPlansCreated,
  'familiesPlanningLunches': instance.familiesPlanningLunches,
  'newFamilies': instance.newFamilies,
  'newFamiliesInvitingAnAdult': instance.newFamiliesInvitingAnAdult,
  'isInviteCohortComplete': instance.isInviteCohortComplete,
  'paywallFamilies': instance.paywallFamilies,
  'paywallFamiliesByTrigger': instance.paywallFamiliesByTrigger,
  'premiumConversions': instance.premiumConversions,
  'premiumConversionsByTrigger': instance.premiumConversionsByTrigger,
  'referralsRedeemed': instance.referralsRedeemed,
  'referralsQualified': instance.referralsQualified,
  'referralMonthsGiven': instance.referralMonthsGiven,
  'computedAt': const NullableTimestampConverter().toJson(instance.computedAt),
};
