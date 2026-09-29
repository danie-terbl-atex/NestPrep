// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lunch_pantry_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LunchPantryEntry _$LunchPantryEntryFromJson(Map<String, dynamic> json) =>
    _LunchPantryEntry(
      id: json['id'] as String,
      portions: (json['portions'] as num?)?.toInt() ?? 0,
      updatedBy: json['updatedBy'] as String,
      updatedAt: const ServerTimestampConverter().fromJson(json['updatedAt']),
    );

Map<String, dynamic> _$LunchPantryEntryToJson(_LunchPantryEntry instance) =>
    <String, dynamic>{
      'portions': instance.portions,
      'updatedBy': instance.updatedBy,
      'updatedAt': const ServerTimestampConverter().toJson(instance.updatedAt),
    };
