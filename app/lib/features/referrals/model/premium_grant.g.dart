// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'premium_grant.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PremiumGrant _$PremiumGrantFromJson(Map<String, dynamic> json) =>
    _PremiumGrant(
      id: json['id'] as String,
      days: (json['days'] as num).toInt(),
      grantedAt: const InstantConverter().fromJson(json['grantedAt']),
      startsAt: const NullableTimestampConverter().fromJson(json['startsAt']),
    );

Map<String, dynamic> _$PremiumGrantToJson(_PremiumGrant instance) =>
    <String, dynamic>{
      'days': instance.days,
      'grantedAt': const InstantConverter().toJson(instance.grantedAt),
      'startsAt': const NullableTimestampConverter().toJson(instance.startsAt),
    };
