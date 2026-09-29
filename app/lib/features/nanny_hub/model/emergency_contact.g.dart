// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'emergency_contact.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EmergencyContact _$EmergencyContactFromJson(Map<String, dynamic> json) =>
    _EmergencyContact(
      id: json['id'] as String,
      name: json['name'] as String,
      kind: $enumDecode(
        _$ContactKindEnumMap,
        json['kind'],
        unknownValue: ContactKind.other,
      ),
      phone: json['phone'] as String,
      note: json['note'] as String?,
      createdBy: json['createdBy'] as String,
      createdAt: const ServerTimestampConverter().fromJson(json['createdAt']),
    );

Map<String, dynamic> _$EmergencyContactToJson(_EmergencyContact instance) =>
    <String, dynamic>{
      'name': instance.name,
      'kind': _$ContactKindEnumMap[instance.kind]!,
      'phone': instance.phone,
      'note': instance.note,
      'createdBy': instance.createdBy,
      'createdAt': const ServerTimestampConverter().toJson(instance.createdAt),
    };

const _$ContactKindEnumMap = {
  ContactKind.parent: 'parent',
  ContactKind.backup: 'backup',
  ContactKind.doctor: 'doctor',
  ContactKind.hospital: 'hospital',
  ContactKind.other: 'other',
};
