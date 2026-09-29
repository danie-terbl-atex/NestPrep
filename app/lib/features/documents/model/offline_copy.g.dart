// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_copy.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_OfflineCopy _$OfflineCopyFromJson(Map<String, dynamic> json) => _OfflineCopy(
  householdId: json['householdId'] as String,
  ownerMemberId: json['ownerMemberId'] as String?,
  documentId: json['documentId'] as String,
  name: json['name'] as String,
  contentType: json['contentType'] as String,
  sizeBytes: (json['sizeBytes'] as num).toInt(),
  savedAt: DateTime.parse(json['savedAt'] as String),
);

Map<String, dynamic> _$OfflineCopyToJson(_OfflineCopy instance) =>
    <String, dynamic>{
      'householdId': instance.householdId,
      'ownerMemberId': instance.ownerMemberId,
      'documentId': instance.documentId,
      'name': instance.name,
      'contentType': instance.contentType,
      'sizeBytes': instance.sizeBytes,
      'savedAt': instance.savedAt.toIso8601String(),
    };
