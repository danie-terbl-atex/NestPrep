// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_completion.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TaskCompletion _$TaskCompletionFromJson(Map<String, dynamic> json) =>
    _TaskCompletion(
      id: json['id'] as String,
      taskId: json['taskId'] as String,
      occurrenceDate: const CalendarDateConverter().fromJson(
        json['occurrenceDate'],
      ),
      completedBy: json['completedBy'] as String,
      completedFor: json['completedFor'] as String,
      completedAt: const ServerTimestampConverter().fromJson(
        json['completedAt'],
      ),
    );

Map<String, dynamic> _$TaskCompletionToJson(
  _TaskCompletion instance,
) => <String, dynamic>{
  'taskId': instance.taskId,
  'occurrenceDate': const CalendarDateConverter().toJson(
    instance.occurrenceDate,
  ),
  'completedBy': instance.completedBy,
  'completedFor': instance.completedFor,
  'completedAt': const ServerTimestampConverter().toJson(instance.completedAt),
};
