// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lunch_budget.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LunchBudget _$LunchBudgetFromJson(Map<String, dynamic> json) => _LunchBudget(
  id: json['id'] as String,
  cents: (json['cents'] as num).toInt(),
  currency: json['currency'] as String? ?? 'ZAR',
  updatedBy: json['updatedBy'] as String,
  updatedAt: const ServerTimestampConverter().fromJson(json['updatedAt']),
);

Map<String, dynamic> _$LunchBudgetToJson(_LunchBudget instance) =>
    <String, dynamic>{
      'cents': instance.cents,
      'currency': instance.currency,
      'updatedBy': instance.updatedBy,
      'updatedAt': const ServerTimestampConverter().toJson(instance.updatedAt),
    };
