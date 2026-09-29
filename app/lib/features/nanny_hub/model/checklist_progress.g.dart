// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checklist_progress.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChecklistProgress _$ChecklistProgressFromJson(Map<String, dynamic> json) =>
    _ChecklistProgress(
      ticked: (json['ticked'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$ChecklistProgressToJson(_ChecklistProgress instance) =>
    <String, dynamic>{'ticked': instance.ticked, 'total': instance.total};
