// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'house_rule.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HouseRule _$HouseRuleFromJson(Map<String, dynamic> json) => _HouseRule(
  id: json['id'] as String,
  text: json['text'] as String,
  createdBy: json['createdBy'] as String,
  createdAt: const ServerTimestampConverter().fromJson(json['createdAt']),
);

Map<String, dynamic> _$HouseRuleToJson(_HouseRule instance) =>
    <String, dynamic>{
      'text': instance.text,
      'createdBy': instance.createdBy,
      'createdAt': const ServerTimestampConverter().toJson(instance.createdAt),
    };
