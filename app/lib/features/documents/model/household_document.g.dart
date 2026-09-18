// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'household_document.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HouseholdDocument _$HouseholdDocumentFromJson(Map<String, dynamic> json) =>
    _HouseholdDocument(
      id: json['id'] as String,
      folderId: json['folderId'] as String,
      name: json['name'] as String,
      contentType: json['contentType'] as String,
      sizeBytes: (json['sizeBytes'] as num).toInt(),
      uploadedBy: json['uploadedBy'] as String,
      uploadedAt: const ServerTimestampConverter().fromJson(json['uploadedAt']),
    );

Map<String, dynamic> _$HouseholdDocumentToJson(
  _HouseholdDocument instance,
) => <String, dynamic>{
  'folderId': instance.folderId,
  'name': instance.name,
  'contentType': instance.contentType,
  'sizeBytes': instance.sizeBytes,
  'uploadedBy': instance.uploadedBy,
  'uploadedAt': const ServerTimestampConverter().toJson(instance.uploadedAt),
};
