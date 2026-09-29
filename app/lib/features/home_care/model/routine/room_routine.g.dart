// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_routine.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RoomRoutine _$RoomRoutineFromJson(Map<String, dynamic> json) => _RoomRoutine(
  id: json['id'] as String,
  name: json['name'] as String,
  roomId: json['roomId'] as String,
  cadence: $enumDecode(
    _$RoutineCadenceEnumMap,
    json['cadence'],
    unknownValue: RoutineCadence.daily,
  ),
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => JobStep.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <JobStep>[],
  helperId: json['helperId'] as String,
  firstDate: const CalendarDateConverter().fromJson(json['firstDate']),
  recurrence: json['recurrence'] == null
      ? null
      : RecurrenceRule.fromJson(json['recurrence'] as Map<String, dynamic>),
  createdBy: json['createdBy'] as String,
  createdAt: const ServerTimestampConverter().fromJson(json['createdAt']),
);

Map<String, dynamic> _$RoomRoutineToJson(_RoomRoutine instance) =>
    <String, dynamic>{
      'name': instance.name,
      'roomId': instance.roomId,
      'cadence': _$RoutineCadenceEnumMap[instance.cadence]!,
      'items': instance.items.map((e) => e.toJson()).toList(),
      'helperId': instance.helperId,
      'firstDate': const CalendarDateConverter().toJson(instance.firstDate),
      'recurrence': instance.recurrence?.toJson(),
      'createdBy': instance.createdBy,
      'createdAt': const ServerTimestampConverter().toJson(instance.createdAt),
    };

const _$RoutineCadenceEnumMap = {
  RoutineCadence.daily: 'daily',
  RoutineCadence.weekly: 'weekly',
  RoutineCadence.deepClean: 'deepClean',
};
