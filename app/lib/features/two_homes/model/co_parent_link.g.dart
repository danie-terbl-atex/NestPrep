// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'co_parent_link.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CoParentLink _$CoParentLinkFromJson(Map<String, dynamic> json) =>
    _CoParentLink(
      id: json['id'] as String,
      status: $enumDecode(
        _$LinkStatusEnumMap,
        json['status'],
        unknownValue: LinkStatus.ended,
      ),
      ownSide: $enumDecode(_$CustodySideEnumMap, json['ownSide']),
      childMemberId: json['childMemberId'] as String,
      childName: json['childName'] as String,
      homes: CoParentHomes.fromJson(json['homes'] as Map<String, dynamic>),
      schedule: CustodySchedule.fromJson(
        json['schedule'] as Map<String, dynamic>,
      ),
      overrides:
          (json['overrides'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const <String, String>{},
      awaitingSide: $enumDecodeNullable(
        _$CustodySideEnumMap,
        json['awaitingSide'],
        unknownValue: JsonKey.nullForUndefinedEnumValue,
      ),
      endedBySide: $enumDecodeNullable(
        _$CustodySideEnumMap,
        json['endedBySide'],
        unknownValue: JsonKey.nullForUndefinedEnumValue,
      ),
      createdAt: const ServerTimestampConverter().fromJson(json['createdAt']),
      updatedAt: const ServerTimestampConverter().fromJson(json['updatedAt']),
    );

Map<String, dynamic> _$CoParentLinkToJson(_CoParentLink instance) =>
    <String, dynamic>{
      'status': _$LinkStatusEnumMap[instance.status]!,
      'ownSide': _$CustodySideEnumMap[instance.ownSide]!,
      'childMemberId': instance.childMemberId,
      'childName': instance.childName,
      'homes': instance.homes.toJson(),
      'schedule': instance.schedule.toJson(),
      'overrides': instance.overrides,
      'awaitingSide': _$CustodySideEnumMap[instance.awaitingSide],
      'endedBySide': _$CustodySideEnumMap[instance.endedBySide],
      'createdAt': const ServerTimestampConverter().toJson(instance.createdAt),
      'updatedAt': const ServerTimestampConverter().toJson(instance.updatedAt),
    };

const _$LinkStatusEnumMap = {
  LinkStatus.pending: 'pending',
  LinkStatus.active: 'active',
  LinkStatus.declined: 'declined',
  LinkStatus.ended: 'ended',
};

const _$CustodySideEnumMap = {CustodySide.a: 'a', CustodySide.b: 'b'};
