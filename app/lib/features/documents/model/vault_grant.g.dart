// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vault_grant.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_VaultGrant _$VaultGrantFromJson(Map<String, dynamic> json) => _VaultGrant(
  id: json['id'] as String,
  memberId: json['memberId'] as String,
  grantedBy: json['grantedBy'] as String,
  grantedAt: const ServerTimestampConverter().fromJson(json['grantedAt']),
);

Map<String, dynamic> _$VaultGrantToJson(_VaultGrant instance) =>
    <String, dynamic>{
      'memberId': instance.memberId,
      'grantedBy': instance.grantedBy,
      'grantedAt': const ServerTimestampConverter().toJson(instance.grantedAt),
    };
