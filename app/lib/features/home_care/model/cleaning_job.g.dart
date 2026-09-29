// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cleaning_job.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CleaningJob _$CleaningJobFromJson(Map<String, dynamic> json) => _CleaningJob(
  id: json['id'] as String,
  title: json['title'] as String,
  roomId: json['roomId'] as String,
  helperId: json['helperId'] as String,
  dueDate: const CalendarDateConverter().fromJson(json['dueDate']),
  note: json['note'] as String?,
  productIds:
      (json['productIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  steps:
      (json['steps'] as List<dynamic>?)
          ?.map((e) => JobStep.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <JobStep>[],
  doneStepIds:
      (json['doneStepIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  beforePhoto: JobPhoto.fromJson(json['beforePhoto'] as Map<String, dynamic>),
  marks:
      (json['marks'] as List<dynamic>?)
          ?.map((e) => SpotMark.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <SpotMark>[],
  afterPhoto: json['afterPhoto'] == null
      ? null
      : JobPhoto.fromJson(json['afterPhoto'] as Map<String, dynamic>),
  status:
      $enumDecodeNullable(
        _$JobStatusEnumMap,
        json['status'],
        unknownValue: JobStatus.assigned,
      ) ??
      JobStatus.assigned,
  reviewNote: json['reviewNote'] as String?,
  revision: (json['revision'] as num?)?.toInt() ?? 0,
  createdBy: json['createdBy'] as String,
  createdAt: const ServerTimestampConverter().fromJson(json['createdAt']),
  updatedAt: const ServerTimestampConverter().fromJson(json['updatedAt']),
);

Map<String, dynamic> _$CleaningJobToJson(_CleaningJob instance) =>
    <String, dynamic>{
      'title': instance.title,
      'roomId': instance.roomId,
      'helperId': instance.helperId,
      'dueDate': const CalendarDateConverter().toJson(instance.dueDate),
      'note': instance.note,
      'productIds': instance.productIds,
      'steps': instance.steps.map((e) => e.toJson()).toList(),
      'doneStepIds': instance.doneStepIds,
      'beforePhoto': instance.beforePhoto.toJson(),
      'marks': instance.marks.map((e) => e.toJson()).toList(),
      'afterPhoto': instance.afterPhoto?.toJson(),
      'status': _$JobStatusEnumMap[instance.status]!,
      'reviewNote': instance.reviewNote,
      'revision': instance.revision,
      'createdBy': instance.createdBy,
      'createdAt': const ServerTimestampConverter().toJson(instance.createdAt),
      'updatedAt': const ServerTimestampConverter().toJson(instance.updatedAt),
    };

const _$JobStatusEnumMap = {
  JobStatus.assigned: 'assigned',
  JobStatus.inProgress: 'inProgress',
  JobStatus.submitted: 'submitted',
  JobStatus.approved: 'approved',
  JobStatus.sentBack: 'sentBack',
};
