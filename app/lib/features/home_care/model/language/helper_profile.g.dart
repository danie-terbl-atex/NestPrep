// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'helper_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HelperProfile _$HelperProfileFromJson(Map<String, dynamic> json) =>
    _HelperProfile(
      id: json['id'] as String,
      language: const HelperLanguageConverter().fromJson(json['language']),
      updatedBy: json['updatedBy'] as String,
      updatedAt: const ServerTimestampConverter().fromJson(json['updatedAt']),
    );

Map<String, dynamic> _$HelperProfileToJson(_HelperProfile instance) =>
    <String, dynamic>{
      'language': const HelperLanguageConverter().toJson(instance.language),
      'updatedBy': instance.updatedBy,
      'updatedAt': const ServerTimestampConverter().toJson(instance.updatedAt),
    };
