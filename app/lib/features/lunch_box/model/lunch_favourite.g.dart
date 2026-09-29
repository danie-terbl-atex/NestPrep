// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lunch_favourite.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LunchFavourite _$LunchFavouriteFromJson(Map<String, dynamic> json) =>
    _LunchFavourite(
      id: json['id'] as String,
      childId: json['childId'] as String,
      name: json['name'] as String,
      picks:
          (json['picks'] as Map<String, dynamic>?)?.map(
            (k, e) =>
                MapEntry(k, LunchPick.fromJson(e as Map<String, dynamic>)),
          ) ??
          const <String, LunchPick>{},
      createdBy: json['createdBy'] as String,
      createdAt: const ServerTimestampConverter().fromJson(json['createdAt']),
    );

Map<String, dynamic> _$LunchFavouriteToJson(_LunchFavourite instance) =>
    <String, dynamic>{
      'childId': instance.childId,
      'name': instance.name,
      'picks': instance.picks.map((k, e) => MapEntry(k, e.toJson())),
      'createdBy': instance.createdBy,
      'createdAt': const ServerTimestampConverter().toJson(instance.createdAt),
    };
