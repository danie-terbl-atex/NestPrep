// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'care_routine.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CareRoutine _$CareRoutineFromJson(Map<String, dynamic> json) => _CareRoutine(
  label: json['label'] as String,
  minuteOfDay: (json['minuteOfDay'] as num?)?.toInt(),
  note: json['note'] as String?,
);

Map<String, dynamic> _$CareRoutineToJson(_CareRoutine instance) =>
    <String, dynamic>{
      'label': instance.label,
      'minuteOfDay': instance.minuteOfDay,
      'note': instance.note,
    };
