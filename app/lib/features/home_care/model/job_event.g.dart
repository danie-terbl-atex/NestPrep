// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_JobEvent _$JobEventFromJson(Map<String, dynamic> json) => _JobEvent(
  id: json['id'] as String,
  status: $enumDecode(
    _$JobStatusEnumMap,
    json['status'],
    unknownValue: JobStatus.assigned,
  ),
  by: json['by'] as String,
  note: json['note'] as String?,
  at: const ServerTimestampConverter().fromJson(json['at']),
);

Map<String, dynamic> _$JobEventToJson(_JobEvent instance) => <String, dynamic>{
  'status': _$JobStatusEnumMap[instance.status]!,
  'by': instance.by,
  'note': instance.note,
  'at': const ServerTimestampConverter().toJson(instance.at),
};

const _$JobStatusEnumMap = {
  JobStatus.assigned: 'assigned',
  JobStatus.inProgress: 'inProgress',
  JobStatus.submitted: 'submitted',
  JobStatus.approved: 'approved',
  JobStatus.sentBack: 'sentBack',
};
