// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Member _$MemberFromJson(Map<String, dynamic> json) => _Member(
  id: json['id'] as String,
  displayName: json['displayName'] as String,
  color: const MemberColorConverter().fromJson(json['color']),
  roleName: json['role'] as String,
  birthday: const BirthdayConverter().fromJson(json['birthday']),
  access: const AccessGrantConverter().fromJson(json['access']),
  claimedBy: json['claimedBy'] as String?,
  createdAt: const ServerTimestampConverter().fromJson(json['createdAt']),
  guardianConsent: json['guardianConsent'] == null
      ? null
      : GuardianConsent.fromJson(
          json['guardianConsent'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$MemberToJson(_Member instance) => <String, dynamic>{
  'displayName': instance.displayName,
  'color': const MemberColorConverter().toJson(instance.color),
  'role': instance.roleName,
  'birthday': const BirthdayConverter().toJson(instance.birthday),
  'access': const AccessGrantConverter().toJson(instance.access),
  'claimedBy': instance.claimedBy,
  'createdAt': const ServerTimestampConverter().toJson(instance.createdAt),
  'guardianConsent': ?instance.guardianConsent?.toJson(),
};
