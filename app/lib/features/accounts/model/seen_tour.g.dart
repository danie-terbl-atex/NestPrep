// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seen_tour.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SeenTour _$SeenTourFromJson(Map<String, dynamic> json) => _SeenTour(
  version: (json['version'] as num).toInt(),
  seenAt: const ServerTimestampConverter().fromJson(json['seenAt']),
);

Map<String, dynamic> _$SeenTourToJson(_SeenTour instance) => <String, dynamic>{
  'version': instance.version,
  'seenAt': const ServerTimestampConverter().toJson(instance.seenAt),
};
