// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'other_allergy.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_OtherAllergy _$OtherAllergyFromJson(Map<String, dynamic> json) =>
    _OtherAllergy(
      name: json['name'] as String,
      severity: const AllergySeverityConverter().fromJson(json['severity']),
      note: json['note'] as String?,
    );

Map<String, dynamic> _$OtherAllergyToJson(_OtherAllergy instance) =>
    <String, dynamic>{
      'name': instance.name,
      'severity': const AllergySeverityConverter().toJson(instance.severity),
      'note': instance.note,
    };
