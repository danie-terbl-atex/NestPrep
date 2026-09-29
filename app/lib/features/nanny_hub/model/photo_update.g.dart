// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'photo_update.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PhotoUpdate _$PhotoUpdateFromJson(Map<String, dynamic> json) => _PhotoUpdate(
  id: json['id'] as String,
  photoId: json['photoId'] as String,
  caption: json['caption'] as String?,
  childIds:
      (json['childIds'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  byMemberId: json['byMemberId'] as String,
  createdAt: const ServerTimestampConverter().fromJson(json['createdAt']),
);

Map<String, dynamic> _$PhotoUpdateToJson(_PhotoUpdate instance) =>
    <String, dynamic>{
      'photoId': instance.photoId,
      'caption': instance.caption,
      'childIds': instance.childIds,
      'byMemberId': instance.byMemberId,
      'createdAt': const ServerTimestampConverter().toJson(instance.createdAt),
    };
