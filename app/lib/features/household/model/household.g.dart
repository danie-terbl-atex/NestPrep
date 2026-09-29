// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'household.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Household _$HouseholdFromJson(Map<String, dynamic> json) => _Household(
  id: json['id'] as String,
  name: json['name'] as String,
  timeZone: json['timeZone'] as String,
  members:
      (json['members'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ) ??
      const <String, String>{},
  access: json['access'] == null
      ? const <String, AccessGrant>{}
      : const GrantsByUidConverter().fromJson(json['access']),
  profiles:
      (json['profiles'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ) ??
      const <String, String>{},
  shiftOnly:
      (json['shiftOnly'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as bool),
      ) ??
      const <String, bool>{},
  pendingSetupStep: json['pendingSetupStep'] as String?,
  createdBy: json['createdBy'] as String?,
  createdAt: const ServerTimestampConverter().fromJson(json['createdAt']),
);

Map<String, dynamic> _$HouseholdToJson(_Household instance) =>
    <String, dynamic>{
      'name': instance.name,
      'timeZone': instance.timeZone,
      'members': instance.members,
      'createdBy': instance.createdBy,
      'createdAt': const ServerTimestampConverter().toJson(instance.createdAt),
    };
