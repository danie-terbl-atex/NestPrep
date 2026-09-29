// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Account _$AccountFromJson(Map<String, dynamic> json) => _Account(
  id: json['id'] as String,
  displayName: json['displayName'] as String,
  photoUrl: json['photoUrl'] as String?,
  householdIds:
      (json['householdIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  activeHouseholdId: json['activeHouseholdId'] as String?,
  createdAt: const ServerTimestampConverter().fromJson(json['createdAt']),
  lastSignedInAt: const ServerTimestampConverter().fromJson(
    json['lastSignedInAt'],
  ),
  legalConsent: json['legalConsent'] == null
      ? null
      : LegalConsent.fromJson(json['legalConsent'] as Map<String, dynamic>),
);

Map<String, dynamic> _$AccountToJson(_Account instance) => <String, dynamic>{
  'displayName': instance.displayName,
  'photoUrl': instance.photoUrl,
  'householdIds': instance.householdIds,
  'activeHouseholdId': instance.activeHouseholdId,
  'createdAt': const ServerTimestampConverter().toJson(instance.createdAt),
  'lastSignedInAt': const ServerTimestampConverter().toJson(
    instance.lastSignedInAt,
  ),
};
