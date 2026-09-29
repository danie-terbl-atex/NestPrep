// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member_health.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MemberHealth _$MemberHealthFromJson(Map<String, dynamic> json) =>
    _MemberHealth(
      id: json['id'] as String,
      medications:
          (json['medications'] as Map<String, dynamic>?)?.map(
            (k, e) =>
                MapEntry(k, Medication.fromJson(e as Map<String, dynamic>)),
          ) ??
          const <String, Medication>{},
    );

Map<String, dynamic> _$MemberHealthToJson(
  _MemberHealth instance,
) => <String, dynamic>{
  'medications': instance.medications.map((k, e) => MapEntry(k, e.toJson())),
};
