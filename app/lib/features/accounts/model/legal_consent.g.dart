// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'legal_consent.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LegalConsent _$LegalConsentFromJson(Map<String, dynamic> json) =>
    _LegalConsent(
      termsVersion: (json['termsVersion'] as num).toInt(),
      privacyVersion: (json['privacyVersion'] as num).toInt(),
      acceptedAt: const ServerTimestampConverter().fromJson(json['acceptedAt']),
    );

Map<String, dynamic> _$LegalConsentToJson(
  _LegalConsent instance,
) => <String, dynamic>{
  'termsVersion': instance.termsVersion,
  'privacyVersion': instance.privacyVersion,
  'acceptedAt': const ServerTimestampConverter().toJson(instance.acceptedAt),
};
