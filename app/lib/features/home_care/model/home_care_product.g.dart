// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_care_product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HomeCareProduct _$HomeCareProductFromJson(Map<String, dynamic> json) =>
    _HomeCareProduct(
      id: json['id'] as String,
      name: json['name'] as String,
      kind: $enumDecode(
        _$ProductKindEnumMap,
        json['kind'],
        unknownValue: ProductKind.other,
      ),
      whereKept: json['whereKept'] as String?,
      note: json['note'] as String?,
      keepFromChildren: json['keepFromChildren'] as bool? ?? false,
      keepFromPets: json['keepFromPets'] as bool? ?? false,
      createdBy: json['createdBy'] as String,
      createdAt: const ServerTimestampConverter().fromJson(json['createdAt']),
    );

Map<String, dynamic> _$HomeCareProductToJson(_HomeCareProduct instance) =>
    <String, dynamic>{
      'name': instance.name,
      'kind': _$ProductKindEnumMap[instance.kind]!,
      'whereKept': instance.whereKept,
      'note': instance.note,
      'keepFromChildren': instance.keepFromChildren,
      'keepFromPets': instance.keepFromPets,
      'createdBy': instance.createdBy,
      'createdAt': const ServerTimestampConverter().toJson(instance.createdAt),
    };

const _$ProductKindEnumMap = {
  ProductKind.bleach: 'bleach',
  ProductKind.ammonia: 'ammonia',
  ProductKind.acidic: 'acidic',
  ProductKind.alcohol: 'alcohol',
  ProductKind.peroxide: 'peroxide',
  ProductKind.ovenCleaner: 'ovenCleaner',
  ProductKind.drainCleaner: 'drainCleaner',
  ProductKind.disinfectant: 'disinfectant',
  ProductKind.allPurpose: 'allPurpose',
  ProductKind.dishSoap: 'dishSoap',
  ProductKind.bicarbonate: 'bicarbonate',
  ProductKind.polish: 'polish',
  ProductKind.floorCleaner: 'floorCleaner',
  ProductKind.other: 'other',
};
