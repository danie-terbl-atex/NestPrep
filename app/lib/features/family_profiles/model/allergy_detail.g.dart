// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'allergy_detail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AllergyDetail _$AllergyDetailFromJson(Map<String, dynamic> json) =>
    _AllergyDetail(
      severity: const AllergySeverityConverter().fromJson(json['severity']),
      note: json['note'] as String?,
    );

Map<String, dynamic> _$AllergyDetailToJson(_AllergyDetail instance) =>
    <String, dynamic>{
      'severity': const AllergySeverityConverter().toJson(instance.severity),
      'note': instance.note,
    };
