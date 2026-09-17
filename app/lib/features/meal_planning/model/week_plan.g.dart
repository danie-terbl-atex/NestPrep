// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'week_plan.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WeekPlan _$WeekPlanFromJson(Map<String, dynamic> json) => _WeekPlan(
  id: json['id'] as String,
  slots:
      (json['slots'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ) ??
      const <String, String>{},
);

Map<String, dynamic> _$WeekPlanToJson(_WeekPlan instance) => <String, dynamic>{
  'slots': instance.slots,
};
