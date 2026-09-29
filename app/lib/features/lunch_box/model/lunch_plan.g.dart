// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lunch_plan.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LunchPlan _$LunchPlanFromJson(Map<String, dynamic> json) => _LunchPlan(
  id: json['id'] as String,
  childId: json['childId'] as String,
  week: json['week'] as String,
  weekStart: json['weekStart'] as String,
  slots:
      (json['slots'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, LunchPick.fromJson(e as Map<String, dynamic>)),
      ) ??
      const <String, LunchPick>{},
  feedback:
      (json['feedback'] as Map<String, dynamic>?)?.map(
        (k, e) =>
            MapEntry(k, LunchFeedback.fromJson(e as Map<String, dynamic>)),
      ) ??
      const <String, LunchFeedback>{},
);

Map<String, dynamic> _$LunchPlanToJson(_LunchPlan instance) =>
    <String, dynamic>{
      'childId': instance.childId,
      'week': instance.week,
      'weekStart': instance.weekStart,
      'slots': instance.slots.map((k, e) => MapEntry(k, e.toJson())),
      'feedback': instance.feedback.map((k, e) => MapEntry(k, e.toJson())),
    };
