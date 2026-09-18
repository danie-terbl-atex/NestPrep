// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_folder.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DocumentFolder _$DocumentFolderFromJson(Map<String, dynamic> json) =>
    _DocumentFolder(
      id: json['id'] as String,
      name: json['name'] as String,
      createdBy: json['createdBy'] as String,
      createdAt: const ServerTimestampConverter().fromJson(json['createdAt']),
    );

Map<String, dynamic> _$DocumentFolderToJson(_DocumentFolder instance) =>
    <String, dynamic>{
      'name': instance.name,
      'createdBy': instance.createdBy,
      'createdAt': const ServerTimestampConverter().toJson(instance.createdAt),
    };
