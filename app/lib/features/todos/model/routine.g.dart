// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routine.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Routine _$RoutineFromJson(Map<String, dynamic> json) => _Routine(
  id: json['id'] as String,
  name: json['name'] as String,
  firstDate: const CalendarDateConverter().fromJson(json['firstDate']),
  recurrence: json['recurrence'] == null
      ? null
      : RecurrenceRule.fromJson(json['recurrence'] as Map<String, dynamic>),
  defaultAssigneeIds:
      (json['defaultAssigneeIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  color: json['color'] == null
      ? MemberColor.violet
      : const MemberColorConverter().fromJson(json['color']),
  createdBy: json['createdBy'] as String,
  createdAt: const ServerTimestampConverter().fromJson(json['createdAt']),
);

Map<String, dynamic> _$RoutineToJson(_Routine instance) => <String, dynamic>{
  'name': instance.name,
  'firstDate': const CalendarDateConverter().toJson(instance.firstDate),
  'recurrence': instance.recurrence,
  'defaultAssigneeIds': instance.defaultAssigneeIds,
  'color': const MemberColorConverter().toJson(instance.color),
  'createdBy': instance.createdBy,
  'createdAt': const ServerTimestampConverter().toJson(instance.createdAt),
};
