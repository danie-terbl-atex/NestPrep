// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shift_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ShiftSummary _$ShiftSummaryFromJson(
  Map<String, dynamic> json,
) => _ShiftSummary(
  id: json['id'] as String,
  carerMemberId: json['carerMemberId'] as String,
  startedAt: const NullableTimestampConverter().fromJson(json['startedAt']),
  endedAt: const NullableTimestampConverter().fromJson(json['endedAt']),
  endedBy: json['endedBy'] as String?,
  counts:
      (json['counts'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toInt()),
      ) ??
      const <String, int>{},
  moments:
      (json['moments'] as List<dynamic>?)
          ?.map((e) => SummaryMoment.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <SummaryMoment>[],
  isTrimmed: json['isTrimmed'] as bool? ?? false,
  entryCount: (json['entryCount'] as num?)?.toInt() ?? 0,
  photoCount: (json['photoCount'] as num?)?.toInt() ?? 0,
  childIds:
      (json['childIds'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  checklist: json['checklist'] == null
      ? const ChecklistProgress()
      : ChecklistProgress.fromJson(json['checklist'] as Map<String, dynamic>),
  closingNote: json['closingNote'] as String?,
);

Map<String, dynamic> _$ShiftSummaryToJson(
  _ShiftSummary instance,
) => <String, dynamic>{
  'carerMemberId': instance.carerMemberId,
  'startedAt': const NullableTimestampConverter().toJson(instance.startedAt),
  'endedAt': const NullableTimestampConverter().toJson(instance.endedAt),
  'endedBy': instance.endedBy,
  'counts': instance.counts,
  'moments': instance.moments.map((e) => e.toJson()).toList(),
  'isTrimmed': instance.isTrimmed,
  'entryCount': instance.entryCount,
  'photoCount': instance.photoCount,
  'childIds': instance.childIds,
  'checklist': instance.checklist.toJson(),
  'closingNote': instance.closingNote,
};
