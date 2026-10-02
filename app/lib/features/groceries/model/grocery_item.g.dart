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
  sourceKey: json['sourceKey'] as String?,
  sourceWeek: json['sourceWeek'] as String?,
  sourceNote: json['sourceNote'] as String?,
  productMatch: const ProductMatchConverter().fromJson(json['productMatch']),
);

Map<String, dynamic> _$GroceryItemToJson(
  _GroceryItem instance,
) => <String, dynamic>{
  'name': instance.name,
  'quantity': instance.quantity,
  'addedBy': instance.addedBy,
  'addedAt': const ServerTimestampConverter().toJson(instance.addedAt),
  'boughtAt': const NullableTimestampConverter().toJson(instance.boughtAt),
  'boughtBy': instance.boughtBy,
  'sourceKey': instance.sourceKey,
  'sourceWeek': instance.sourceWeek,
  'sourceNote': instance.sourceNote,
  'productMatch': ?const ProductMatchConverter().toJson(instance.productMatch),
};
