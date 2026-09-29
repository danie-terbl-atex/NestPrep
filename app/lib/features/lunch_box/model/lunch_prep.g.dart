// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lunch_prep.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LunchPrep _$LunchPrepFromJson(Map<String, dynamic> json) => _LunchPrep(
  id: json['id'] as String,
  done:
      (json['done'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
);

Map<String, dynamic> _$LunchPrepToJson(_LunchPrep instance) =>
    <String, dynamic>{'done': instance.done};
