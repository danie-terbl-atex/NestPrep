// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shift.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Shift _$ShiftFromJson(Map<String, dynamic> json) => _Shift(
  id: json['id'] as String,
  carerMemberId: json['carerMemberId'] as String,
  startedBy: json['startedBy'] as String,
  startedAt: const ServerTimestampConverter().fromJson(json['startedAt']),
  endedAt: const NullableTimestampConverter().fromJson(json['endedAt']),
  endedBy: json['endedBy'] as String?,
  status: json['status'] as String? ?? Shift.open,
  ticks:
      (json['ticks'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as bool),
      ) ??
      const <String, bool>{},
);

Map<String, dynamic> _$ShiftToJson(_Shift instance) => <String, dynamic>{
  'carerMemberId': instance.carerMemberId,
  'startedBy': instance.startedBy,
  'startedAt': const ServerTimestampConverter().toJson(instance.startedAt),
  'endedAt': const NullableTimestampConverter().toJson(instance.endedAt),
  'endedBy': instance.endedBy,
  'status': instance.status,
  'ticks': instance.ticks,
};
