// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vault_view.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_VaultView _$VaultViewFromJson(Map<String, dynamic> json) => _VaultView(
  id: json['id'] as String,
  documentId: json['documentId'] as String,
  documentName: json['documentName'] as String,
  viewerMemberId: json['viewerMemberId'] as String?,
  shareId: json['shareId'] as String?,
  viewedAt: const ServerTimestampConverter().fromJson(json['viewedAt']),
);

Map<String, dynamic> _$VaultViewToJson(_VaultView instance) =>
    <String, dynamic>{
      'documentId': instance.documentId,
      'documentName': instance.documentName,
      'viewerMemberId': instance.viewerMemberId,
      'shareId': instance.shareId,
      'viewedAt': const ServerTimestampConverter().toJson(instance.viewedAt),
    };
