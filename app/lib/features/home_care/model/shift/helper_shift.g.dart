// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'helper_shift.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HelperShift _$HelperShiftFromJson(Map<String, dynamic> json) => _HelperShift(
  id: json['id'] as String,
  helperId: json['helperId'] as String,
  startedBy: json['startedBy'] as String,
  startedAt: const ServerTimestampConverter().fromJson(json['startedAt']),
  startedVia: json['startedVia'] as String? ?? HelperShift.app,
  endedAt: const NullableTimestampConverter().fromJson(json['endedAt']),
  endedBy: json['endedBy'] as String?,
  endedVia: json['endedVia'] as String?,
  status: json['status'] as String? ?? HelperShift.open,
);

Map<String, dynamic> _$HelperShiftToJson(_HelperShift instance) =>
    <String, dynamic>{
      'helperId': instance.helperId,
      'startedBy': instance.startedBy,
      'startedAt': const ServerTimestampConverter().toJson(instance.startedAt),
      'startedVia': instance.startedVia,
      'endedAt': const NullableTimestampConverter().toJson(instance.endedAt),
      'endedBy': instance.endedBy,
      'endedVia': instance.endedVia,
      'status': instance.status,
    };
