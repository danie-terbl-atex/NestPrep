// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'household_referral.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HouseholdReferral _$HouseholdReferralFromJson(Map<String, dynamic> json) =>
    _HouseholdReferral(
      code: json['code'] as String?,
      redeemBy: const NullableTimestampConverter().fromJson(json['redeemBy']),
      hasRedeemed: json['hasRedeemed'] as bool? ?? false,
      yearlyRewardCap: (json['yearlyRewardCap'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$HouseholdReferralToJson(_HouseholdReferral instance) =>
    <String, dynamic>{
      'code': instance.code,
      'redeemBy': const NullableTimestampConverter().toJson(instance.redeemBy),
      'hasRedeemed': instance.hasRedeemed,
      'yearlyRewardCap': instance.yearlyRewardCap,
    };
