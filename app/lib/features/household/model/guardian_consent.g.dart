// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'guardian_consent.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GuardianConsent _$GuardianConsentFromJson(Map<String, dynamic> json) =>
    _GuardianConsent(
      byMemberId: json['byMemberId'] as String,
      version: (json['version'] as num).toInt(),
      at: const ServerTimestampConverter().fromJson(json['at']),
    );

Map<String, dynamic> _$GuardianConsentToJson(_GuardianConsent instance) =>
    <String, dynamic>{
      'byMemberId': instance.byMemberId,
      'version': instance.version,
      'at': const ServerTimestampConverter().toJson(instance.at),
    };
