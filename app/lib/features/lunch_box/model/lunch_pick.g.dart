// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lunch_pick.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LunchPick _$LunchPickFromJson(Map<String, dynamic> json) => _LunchPick(
  itemId: json['itemId'] as String,
  name: json['name'] as String,
  allergens:
      (json['allergens'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
);

Map<String, dynamic> _$LunchPickToJson(_LunchPick instance) =>
    <String, dynamic>{
      'itemId': instance.itemId,
      'name': instance.name,
      'allergens': instance.allergens,
    };
