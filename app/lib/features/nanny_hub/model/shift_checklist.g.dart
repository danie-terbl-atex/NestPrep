// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shift_checklist.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ShiftChecklist _$ShiftChecklistFromJson(Map<String, dynamic> json) =>
    _ShiftChecklist(
      id: json['id'] as String,
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => ChecklistItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <ChecklistItem>[],
      updatedBy: json['updatedBy'] as String?,
      updatedAt: const ServerTimestampConverter().fromJson(json['updatedAt']),
    );

Map<String, dynamic> _$ShiftChecklistToJson(_ShiftChecklist instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'updatedBy': instance.updatedBy,
      'updatedAt': const ServerTimestampConverter().toJson(instance.updatedAt),
    };
