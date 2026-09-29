// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pickup_person.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PickupPerson _$PickupPersonFromJson(Map<String, dynamic> json) =>
    _PickupPerson(
      id: json['id'] as String,
      name: json['name'] as String,
      relationship: json['relationship'] as String,
      idNote: json['idNote'] as String?,
      phone: json['phone'] as String?,
      photoId: json['photoId'] as String?,
      childIds:
          (json['childIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      createdBy: json['createdBy'] as String,
      createdAt: const ServerTimestampConverter().fromJson(json['createdAt']),
    );

Map<String, dynamic> _$PickupPersonToJson(_PickupPerson instance) =>
    <String, dynamic>{
      'name': instance.name,
      'relationship': instance.relationship,
      'idNote': instance.idNote,
      'phone': instance.phone,
      'photoId': instance.photoId,
      'childIds': instance.childIds,
      'createdBy': instance.createdBy,
      'createdAt': const ServerTimestampConverter().toJson(instance.createdAt),
    };
