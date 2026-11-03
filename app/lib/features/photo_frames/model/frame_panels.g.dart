// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'frame_panels.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FramePanels _$FramePanelsFromJson(Map<String, dynamic> json) => _FramePanels(
  calendar: json['calendar'] as bool? ?? true,
  todos: json['todos'] as bool? ?? true,
  meals: json['meals'] as bool? ?? true,
  lunch: json['lunch'] as bool? ?? false,
  addEvents: json['addEvents'] as bool? ?? false,
  share: json['share'] as bool? ?? false,
  helperMemberId: json['helperMemberId'] as String?,
);

Map<String, dynamic> _$FramePanelsToJson(_FramePanels instance) =>
    <String, dynamic>{
      'calendar': instance.calendar,
      'todos': instance.todos,
      'meals': instance.meals,
      'lunch': instance.lunch,
      'addEvents': instance.addEvents,
      'share': instance.share,
      'helperMemberId': instance.helperMemberId,
    };
