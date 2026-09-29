// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pickup_change.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PickupChange _$PickupChangeFromJson(Map<String, dynamic> json) =>
    _PickupChange(
      id: json['id'] as String,
      childId: json['childId'] as String,
      date: const CalendarDateConverter().fromJson(json['date']),
      personId: json['personId'] as String?,
      memberId: json['memberId'] as String?,
      atMinute: (json['atMinute'] as num?)?.toInt(),
      note: json['note'] as String?,
      updatedBy: json['updatedBy'] as String,
      updatedAt: const ServerTimestampConverter().fromJson(json['updatedAt']),
    );

Map<String, dynamic> _$PickupChangeToJson(_PickupChange instance) =>
    <String, dynamic>{
      'childId': instance.childId,
      'date': const CalendarDateConverter().toJson(instance.date),
      'personId': instance.personId,
      'memberId': instance.memberId,
      'atMinute': instance.atMinute,
      'note': instance.note,
      'updatedBy': instance.updatedBy,
      'updatedAt': const ServerTimestampConverter().toJson(instance.updatedAt),
    };
