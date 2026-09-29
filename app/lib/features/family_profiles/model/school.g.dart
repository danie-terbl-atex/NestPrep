// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'school.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_School _$SchoolFromJson(Map<String, dynamic> json) => _School(
  id: json['id'] as String,
  name: json['name'] as String,
  nutFree: json['nutFree'] as bool? ?? false,
  createdAt: const ServerTimestampConverter().fromJson(json['createdAt']),
);

Map<String, dynamic> _$SchoolToJson(_School instance) => <String, dynamic>{
  'name': instance.name,
  'nutFree': instance.nutFree,
  'createdAt': const ServerTimestampConverter().toJson(instance.createdAt),
};
