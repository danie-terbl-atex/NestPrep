// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member_location.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MemberLocation _$MemberLocationFromJson(Map<String, dynamic> json) =>
    _MemberLocation(
      id: json['id'] as String,
      point: const CoordinatesConverter().fromJson(json['point']),
      accuracyMetres: (json['accuracyMetres'] as num).toInt(),
      reportedAt: const ServerTimestampConverter().fromJson(json['reportedAt']),
      sharingUntil: const InstantConverter().fromJson(json['sharingUntil']),
    );

Map<String, dynamic> _$MemberLocationToJson(
  _MemberLocation instance,
) => <String, dynamic>{
  'point': const CoordinatesConverter().toJson(instance.point),
  'accuracyMetres': instance.accuracyMetres,
  'reportedAt': const ServerTimestampConverter().toJson(instance.reportedAt),
  'sharingUntil': const InstantConverter().toJson(instance.sharingUntil),
};
