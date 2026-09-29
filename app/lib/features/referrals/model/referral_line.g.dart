// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'referral_line.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ReferralLine _$ReferralLineFromJson(
  Map<String, dynamic> json,
) => _ReferralLine(
  id: json['id'] as String,
  side:
      $enumDecodeNullable(
        _$ReferralSideEnumMap,
        json['side'],
        unknownValue: ReferralSide.referred,
      ) ??
      ReferralSide.referred,
  status:
      $enumDecodeNullable(
        _$ReferralStatusEnumMap,
        json['status'],
        unknownValue: ReferralStatus.pending,
      ) ??
      ReferralStatus.pending,
  redeemedAt: const NullableTimestampConverter().fromJson(json['redeemedAt']),
  qualifyBy: const NullableTimestampConverter().fromJson(json['qualifyBy']),
  qualifiedAt: const NullableTimestampConverter().fromJson(json['qualifiedAt']),
  reward: $enumDecodeNullable(
    _$ReferralRewardEnumMap,
    json['reward'],
    unknownValue: JsonKey.nullForUndefinedEnumValue,
  ),
);

Map<String, dynamic> _$ReferralLineToJson(
  _ReferralLine instance,
) => <String, dynamic>{
  'side': _$ReferralSideEnumMap[instance.side]!,
  'status': _$ReferralStatusEnumMap[instance.status]!,
  'redeemedAt': const NullableTimestampConverter().toJson(instance.redeemedAt),
  'qualifyBy': const NullableTimestampConverter().toJson(instance.qualifyBy),
  'qualifiedAt': const NullableTimestampConverter().toJson(
    instance.qualifiedAt,
  ),
  'reward': _$ReferralRewardEnumMap[instance.reward],
};

const _$ReferralSideEnumMap = {
  ReferralSide.referrer: 'referrer',
  ReferralSide.referred: 'referred',
};

const _$ReferralStatusEnumMap = {
  ReferralStatus.pending: 'pending',
  ReferralStatus.qualified: 'qualified',
  ReferralStatus.expired: 'expired',
};

const _$ReferralRewardEnumMap = {
  ReferralReward.month: 'month',
  ReferralReward.capped: 'capped',
};
