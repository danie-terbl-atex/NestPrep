// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'grocery_plan_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GroceryPlanSettings _$GroceryPlanSettingsFromJson(Map<String, dynamic> json) =>
    _GroceryPlanSettings(
      keepInStep: json['keepInStep'] as bool? ?? false,
      staples:
          (json['staples'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      updatedBy: json['updatedBy'] as String?,
      updatedAt: const ServerTimestampConverter().fromJson(json['updatedAt']),
    );

Map<String, dynamic> _$GroceryPlanSettingsToJson(
  _GroceryPlanSettings instance,
) => <String, dynamic>{
  'keepInStep': instance.keepInStep,
  'staples': instance.staples,
  'updatedBy': instance.updatedBy,
  'updatedAt': const ServerTimestampConverter().toJson(instance.updatedAt),
};
