// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'family_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FamilyProfile _$FamilyProfileFromJson(Map<String, dynamic> json) =>
    _FamilyProfile(
      id: json['id'] as String,
      isChild: json['isChild'] as bool? ?? false,
      likes:
          (json['likes'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const <String>[],
      dislikes:
          (json['dislikes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      diet: json['diet'] == null
          ? const <DietaryFlag>{}
          : const DietaryFlagsConverter().fromJson(json['diet']),
      allergies: json['allergies'] == null
          ? const <Allergen, AllergyDetail>{}
          : const AllergenMapConverter().fromJson(json['allergies']),
      otherAllergies:
          (json['otherAllergies'] as Map<String, dynamic>?)?.map(
            (k, e) =>
                MapEntry(k, OtherAllergy.fromJson(e as Map<String, dynamic>)),
          ) ??
          const <String, OtherAllergy>{},
      schoolId: json['schoolId'] as String?,
      grade: json['grade'] as String?,
      clothingSize: json['clothingSize'] as String?,
      shoeSize: json['shoeSize'] as String?,
    );

Map<String, dynamic> _$FamilyProfileToJson(_FamilyProfile instance) =>
    <String, dynamic>{
      'isChild': instance.isChild,
      'likes': instance.likes,
      'dislikes': instance.dislikes,
      'diet': const DietaryFlagsConverter().toJson(instance.diet),
      'allergies': const AllergenMapConverter().toJson(instance.allergies),
      'otherAllergies': instance.otherAllergies.map(
        (k, e) => MapEntry(k, e.toJson()),
      ),
      'schoolId': instance.schoolId,
      'grade': instance.grade,
      'clothingSize': instance.clothingSize,
      'shoeSize': instance.shoeSize,
    };
