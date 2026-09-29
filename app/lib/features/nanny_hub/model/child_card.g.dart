// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'child_card.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChildCard _$ChildCardFromJson(Map<String, dynamic> json) => _ChildCard(
  id: json['id'] as String,
  routines:
      (json['routines'] as List<dynamic>?)
          ?.map((e) => CareRoutine.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <CareRoutine>[],
  comfortItems:
      (json['comfortItems'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  settling: json['settling'] as String?,
  goodToKnow: json['goodToKnow'] as String?,
  photoId: json['photoId'] as String?,
  updatedBy: json['updatedBy'] as String?,
  updatedAt: const ServerTimestampConverter().fromJson(json['updatedAt']),
);

Map<String, dynamic> _$ChildCardToJson(_ChildCard instance) =>
    <String, dynamic>{
      'routines': instance.routines.map((e) => e.toJson()).toList(),
      'comfortItems': instance.comfortItems,
      'settling': instance.settling,
      'goodToKnow': instance.goodToKnow,
      'photoId': instance.photoId,
      'updatedBy': instance.updatedBy,
      'updatedAt': const ServerTimestampConverter().toJson(instance.updatedAt),
    };
