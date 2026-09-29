// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal_ingredient.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MealIngredient _$MealIngredientFromJson(Map<String, dynamic> json) =>
    _MealIngredient(
      name: json['name'] as String,
      amount: (json['amount'] as num?)?.toDouble(),
      unitCode: json['unit'] as String?,
    );

Map<String, dynamic> _$MealIngredientToJson(_MealIngredient instance) =>
    <String, dynamic>{
      'name': instance.name,
      'amount': instance.amount,
      'unit': instance.unitCode,
    };
