// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_sheet.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HomeSheet _$HomeSheetFromJson(Map<String, dynamic> json) => _HomeSheet(
  id: json['id'] as String? ?? HomeSheet.documentId,
  address: json['address'] as String?,
  medicalAidScheme: json['medicalAidScheme'] as String?,
  medicalAidPlan: json['medicalAidPlan'] as String?,
  medicalAidNumber: json['medicalAidNumber'] as String?,
  updatedBy: json['updatedBy'] as String?,
  updatedAt: const ServerTimestampConverter().fromJson(json['updatedAt']),
);

Map<String, dynamic> _$HomeSheetToJson(_HomeSheet instance) =>
    <String, dynamic>{
      'address': instance.address,
      'medicalAidScheme': instance.medicalAidScheme,
      'medicalAidPlan': instance.medicalAidPlan,
      'medicalAidNumber': instance.medicalAidNumber,
      'updatedBy': instance.updatedBy,
      'updatedAt': const ServerTimestampConverter().toJson(instance.updatedAt),
    };
