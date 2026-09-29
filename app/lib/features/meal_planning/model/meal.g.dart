// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Meal _$MealFromJson(Map<String, dynamic> json) => _Meal(
  id: json['id'] as String,
  name: json['name'] as String,
  nameKey: json['nameKey'] as String,
  addedBy: json['addedBy'] as String,
  createdAt: const ServerTimestampConverter().fromJson(json['createdAt']),
  ingredients: json['ingredients'] == null
      ? const <MealIngredient>[]
      : const MealIngredientsConverter().fromJson(json['ingredients'] as List?),
);

Map<String, dynamic> _$MealToJson(_Meal instance) => <String, dynamic>{
  'name': instance.name,
  'nameKey': instance.nameKey,
  'addedBy': instance.addedBy,
  'createdAt': const ServerTimestampConverter().toJson(instance.createdAt),
  'ingredients': const MealIngredientsConverter().toJson(instance.ingredients),
};
