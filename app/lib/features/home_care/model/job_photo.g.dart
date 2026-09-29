// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_photo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_JobPhoto _$JobPhotoFromJson(Map<String, dynamic> json) => _JobPhoto(
  photoId: json['photoId'] as String,
  width: (json['width'] as num).toInt(),
  height: (json['height'] as num).toInt(),
);

Map<String, dynamic> _$JobPhotoToJson(_JobPhoto instance) => <String, dynamic>{
  'photoId': instance.photoId,
  'width': instance.width,
  'height': instance.height,
};
