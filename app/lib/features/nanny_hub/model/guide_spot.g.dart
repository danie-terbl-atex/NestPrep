// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'guide_spot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GuideSpot _$GuideSpotFromJson(Map<String, dynamic> json) => _GuideSpot(
  id: json['id'] as String,
  title: json['title'] as String,
  note: json['note'] as String?,
  photoId: json['photoId'] as String?,
  createdBy: json['createdBy'] as String,
  createdAt: const ServerTimestampConverter().fromJson(json['createdAt']),
);

Map<String, dynamic> _$GuideSpotToJson(_GuideSpot instance) =>
    <String, dynamic>{
      'title': instance.title,
      'note': instance.note,
      'photoId': instance.photoId,
      'createdBy': instance.createdBy,
      'createdAt': const ServerTimestampConverter().toJson(instance.createdAt),
    };
