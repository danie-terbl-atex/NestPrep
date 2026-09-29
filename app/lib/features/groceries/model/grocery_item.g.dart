// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'grocery_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GroceryItem _$GroceryItemFromJson(Map<String, dynamic> json) => _GroceryItem(
  id: json['id'] as String,
  name: json['name'] as String,
  quantity: json['quantity'] as String?,
  addedBy: json['addedBy'] as String,
  addedAt: const ServerTimestampConverter().fromJson(json['addedAt']),
  boughtAt: const NullableTimestampConverter().fromJson(json['boughtAt']),
  boughtBy: json['boughtBy'] as String?,
  source: json['source'] as String?,
);

Map<String, dynamic> _$GroceryItemToJson(_GroceryItem instance) =>
    <String, dynamic>{
      'name': instance.name,
      'quantity': instance.quantity,
      'addedBy': instance.addedBy,
      'addedAt': const ServerTimestampConverter().toJson(instance.addedAt),
      'boughtAt': const NullableTimestampConverter().toJson(instance.boughtAt),
      'boughtBy': instance.boughtBy,
      'source': ?instance.source,
    };
