// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kid_routine_step.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_KidRoutinePart _$KidRoutinePartFromJson(Map<String, dynamic> json) =>
    _KidRoutinePart(
      id: json['id'] as String,
      text: json['text'] as String,
      picture: json['picture'] as String?,
      weekdays:
          (json['weekdays'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const <int>[],
    );

Map<String, dynamic> _$KidRoutinePartToJson(_KidRoutinePart instance) =>
    <String, dynamic>{
      'id': instance.id,
      'text': instance.text,
      'picture': ?instance.picture,
      'weekdays': instance.weekdays,
    };

_KidRoutineStep _$KidRoutineStepFromJson(Map<String, dynamic> json) =>
    _KidRoutineStep(
      id: json['id'] as String,
      title: json['title'] as String,
      picture: json['picture'] as String?,
      note: json['note'] as String?,
      parts:
          (json['parts'] as List<dynamic>?)
              ?.map((e) => KidRoutinePart.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <KidRoutinePart>[],
    );

Map<String, dynamic> _$KidRoutineStepToJson(_KidRoutineStep instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'picture': ?instance.picture,
      'note': ?instance.note,
      'parts': instance.parts.map((e) => e.toJson()).toList(),
    };
