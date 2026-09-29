// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lunch_price.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LunchPrice _$LunchPriceFromJson(Map<String, dynamic> json) => _LunchPrice(
  id: json['id'] as String,
  cents: (json['cents'] as num).toInt(),
  portions: (json['portions'] as num?)?.toInt() ?? 1,
  currency: json['currency'] as String? ?? 'ZAR',
  updatedBy: json['updatedBy'] as String,
  updatedAt: const ServerTimestampConverter().fromJson(json['updatedAt']),
);

Map<String, dynamic> _$LunchPriceToJson(_LunchPrice instance) =>
    <String, dynamic>{
      'cents': instance.cents,
      'portions': instance.portions,
      'currency': instance.currency,
      'updatedBy': instance.updatedBy,
      'updatedAt': const ServerTimestampConverter().toJson(instance.updatedAt),
    };
