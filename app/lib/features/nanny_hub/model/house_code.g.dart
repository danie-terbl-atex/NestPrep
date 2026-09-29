// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'house_code.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HouseCode _$HouseCodeFromJson(Map<String, dynamic> json) => _HouseCode(
  id: json['id'] as String,
  label: json['label'] as String,
  value: json['value'] as String,
  note: json['note'] as String?,
  createdBy: json['createdBy'] as String,
  createdAt: const ServerTimestampConverter().fromJson(json['createdAt']),
);

Map<String, dynamic> _$HouseCodeToJson(_HouseCode instance) =>
    <String, dynamic>{
      'label': instance.label,
      'value': instance.value,
      'note': instance.note,
      'createdBy': instance.createdBy,
      'createdAt': const ServerTimestampConverter().toJson(instance.createdAt),
    };
