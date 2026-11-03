// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'grant_days_waiting.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GrantDaysWaiting _$GrantDaysWaitingFromJson(Map<String, dynamic> json) =>
    _GrantDaysWaiting(
      referral: (json['referral'] as num?)?.toInt() ?? 0,
      frame: (json['frame'] as num?)?.toInt() ?? 0,
      code: (json['code'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$GrantDaysWaitingToJson(_GrantDaysWaiting instance) =>
    <String, dynamic>{
      'referral': instance.referral,
      'frame': instance.frame,
      'code': instance.code,
    };
