// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medication.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Medication _$MedicationFromJson(Map<String, dynamic> json) => _Medication(
  name: json['name'] as String,
  dose: json['dose'] as String?,
  times:
      (json['times'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      const <int>[],
  note: json['note'] as String?,
);

Map<String, dynamic> _$MedicationToJson(_Medication instance) =>
    <String, dynamic>{
      'name': instance.name,
      'dose': instance.dose,
      'times': instance.times,
      'note': instance.note,
    };
