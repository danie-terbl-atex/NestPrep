// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kid_routine.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_KidRoutine _$KidRoutineFromJson(Map<String, dynamic> json) => _KidRoutine(
  id: json['id'] as String,
  name: json['name'] as String,
  slot: $enumDecode(
    _$KidRoutineSlotEnumMap,
    json['slot'],
    unknownValue: KidRoutineSlot.morning,
  ),
  kidIds:
      (json['kidIds'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  firstDate: const CalendarDateConverter().fromJson(json['firstDate']),
  recurrence: json['recurrence'] == null
      ? null
      : RecurrenceRule.fromJson(json['recurrence'] as Map<String, dynamic>),
  finishBy: (json['finishBy'] as num?)?.toInt(),
  points: (json['points'] as num?)?.toInt() ?? 0,
  steps:
      (json['steps'] as List<dynamic>?)
          ?.map((e) => KidRoutineStep.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <KidRoutineStep>[],
  createdBy: json['createdBy'] as String,
  createdAt: const ServerTimestampConverter().fromJson(json['createdAt']),
);

Map<String, dynamic> _$KidRoutineToJson(_KidRoutine instance) =>
    <String, dynamic>{
      'name': instance.name,
      'slot': _$KidRoutineSlotEnumMap[instance.slot]!,
      'kidIds': instance.kidIds,
      'firstDate': const CalendarDateConverter().toJson(instance.firstDate),
      'recurrence': instance.recurrence?.toJson(),
      'finishBy': instance.finishBy,
      'points': instance.points,
      'steps': instance.steps.map((e) => e.toJson()).toList(),
      'createdBy': instance.createdBy,
      'createdAt': const ServerTimestampConverter().toJson(instance.createdAt),
    };

const _$KidRoutineSlotEnumMap = {
  KidRoutineSlot.morning: 'morning',
  KidRoutineSlot.afternoon: 'afternoon',
  KidRoutineSlot.bedtime: 'bedtime',
};
