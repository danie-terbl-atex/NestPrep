// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Task _$TaskFromJson(Map<String, dynamic> json) => _Task(
  id: json['id'] as String,
  title: json['title'] as String,
  note: json['note'] as String?,
  dueDate: const CalendarDateConverter().fromJson(json['dueDate']),
  recurrence: json['recurrence'] == null
      ? null
      : RecurrenceRule.fromJson(json['recurrence'] as Map<String, dynamic>),
  assigneeIds:
      (json['assigneeIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  createdBy: json['createdBy'] as String,
  routineId: json['routineId'] as String?,
  createdAt: const ServerTimestampConverter().fromJson(json['createdAt']),
);

Map<String, dynamic> _$TaskToJson(_Task instance) => <String, dynamic>{
  'title': instance.title,
  'note': instance.note,
  'dueDate': const CalendarDateConverter().toJson(instance.dueDate),
  'recurrence': instance.recurrence?.toJson(),
  'assigneeIds': instance.assigneeIds,
  'createdBy': instance.createdBy,
  'routineId': instance.routineId,
  'createdAt': const ServerTimestampConverter().toJson(instance.createdAt),
};
