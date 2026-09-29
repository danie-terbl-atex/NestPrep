// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lunch_feedback.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LunchFeedback _$LunchFeedbackFromJson(Map<String, dynamic> json) =>
    _LunchFeedback(
      verdict: json['verdict'] as String,
      items:
          (json['items'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const <String, String>{},
      by: json['by'] as String,
      at: const ServerTimestampConverter().fromJson(json['at']),
    );

Map<String, dynamic> _$LunchFeedbackToJson(_LunchFeedback instance) =>
    <String, dynamic>{
      'verdict': instance.verdict,
      'items': instance.items,
      'by': instance.by,
      'at': const ServerTimestampConverter().toJson(instance.at),
    };
