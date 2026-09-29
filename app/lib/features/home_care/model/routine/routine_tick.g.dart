// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routine_tick.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RoutineTick _$RoutineTickFromJson(Map<String, dynamic> json) => _RoutineTick(
  id: json['id'] as String,
  routineId: json['routineId'] as String,
  occurrenceDate: const CalendarDateConverter().fromJson(
    json['occurrenceDate'],
  ),
  helperId: json['helperId'] as String,
  doneItemIds:
      (json['doneItemIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  updatedBy: json['updatedBy'] as String,
  updatedAt: const ServerTimestampConverter().fromJson(json['updatedAt']),
);

Map<String, dynamic> _$RoutineTickToJson(_RoutineTick instance) =>
    <String, dynamic>{
      'routineId': instance.routineId,
      'occurrenceDate': const CalendarDateConverter().toJson(
        instance.occurrenceDate,
      ),
      'helperId': instance.helperId,
      'doneItemIds': instance.doneItemIds,
      'updatedBy': instance.updatedBy,
      'updatedAt': const ServerTimestampConverter().toJson(instance.updatedAt),
    };
