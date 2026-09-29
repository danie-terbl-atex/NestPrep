// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_share.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DocumentShare _$DocumentShareFromJson(Map<String, dynamic> json) =>
    _DocumentShare(
      id: json['id'] as String,
      scope: json['scope'] as String,
      ownerMemberId: json['ownerMemberId'] as String?,
      documentId: json['documentId'] as String,
      documentName: json['documentName'] as String,
      contentType: json['contentType'] as String,
      createdBy: json['createdBy'] as String?,
      createdByUid: json['createdByUid'] as String,
      createdAt: const NullableTimestampConverter().fromJson(json['createdAt']),
      expiresAt: const InstantConverter().fromJson(json['expiresAt']),
      shiftId: json['shiftId'] as String?,
      hasPin: json['hasPin'] as bool,
      status: json['status'] as String? ?? DocumentShare.active,
      openCount: (json['openCount'] as num?)?.toInt() ?? 0,
      lastOpenedAt: const NullableTimestampConverter().fromJson(
        json['lastOpenedAt'],
      ),
    );

Map<String, dynamic> _$DocumentShareToJson(
  _DocumentShare instance,
) => <String, dynamic>{
  'scope': instance.scope,
  'ownerMemberId': instance.ownerMemberId,
  'documentId': instance.documentId,
  'documentName': instance.documentName,
  'contentType': instance.contentType,
  'createdBy': instance.createdBy,
  'createdByUid': instance.createdByUid,
  'createdAt': const NullableTimestampConverter().toJson(instance.createdAt),
  'expiresAt': const InstantConverter().toJson(instance.expiresAt),
  'shiftId': instance.shiftId,
  'hasPin': instance.hasPin,
  'status': instance.status,
  'openCount': instance.openCount,
  'lastOpenedAt': const NullableTimestampConverter().toJson(
    instance.lastOpenedAt,
  ),
};
