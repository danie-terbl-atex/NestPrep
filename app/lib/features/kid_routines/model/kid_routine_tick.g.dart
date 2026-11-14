// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kid_routine_tick.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_KidRoutineTick _$KidRoutineTickFromJson(Map<String, dynamic> json) =>
    _KidRoutineTick(
      routineId: json['routineId'] as String,
      kidId: json['kidId'] as String,
      occurrenceDate: const CalendarDateConverter().fromJson(
        json['occurrenceDate'],
      ),
      doneStepIds:
          (json['doneStepIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      updatedBy: json['updatedBy'] as String,
      updatedAt: const ServerTimestampConverter().fromJson(json['updatedAt']),
    );

Map<String, dynamic> _$KidRoutineTickToJson(_KidRoutineTick instance) =>
    <String, dynamic>{
      'routineId': instance.routineId,
      'kidId': instance.kidId,
      'occurrenceDate': const CalendarDateConverter().toJson(
        instance.occurrenceDate,
      ),
      'doneStepIds': instance.doneStepIds,
      'updatedBy': instance.updatedBy,
      'updatedAt': const ServerTimestampConverter().toJson(instance.updatedAt),
    };
