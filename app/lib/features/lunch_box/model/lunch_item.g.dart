// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lunch_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LunchItem _$LunchItemFromJson(Map<String, dynamic> json) => _LunchItem(
  id: json['id'] as String,
  name: json['name'] as String,
  nameKey: json['nameKey'] as String,
  slotName: json['slot'] as String,
  allergens:
      (json['allergens'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  prepAhead: json['prepAhead'] as bool? ?? false,
  prepNote: json['prepNote'] as String?,
  archived: json['archived'] as bool? ?? false,
  seedKey: json['seedKey'] as String?,
  addedBy: json['addedBy'] as String,
  createdAt: const ServerTimestampConverter().fromJson(json['createdAt']),
);

Map<String, dynamic> _$LunchItemToJson(_LunchItem instance) =>
    <String, dynamic>{
      'name': instance.name,
      'nameKey': instance.nameKey,
      'slot': instance.slotName,
      'allergens': instance.allergens,
      'prepAhead': instance.prepAhead,
      'prepNote': instance.prepNote,
      'archived': instance.archived,
      'seedKey': instance.seedKey,
      'addedBy': instance.addedBy,
      'createdAt': const ServerTimestampConverter().toJson(instance.createdAt),
    };
