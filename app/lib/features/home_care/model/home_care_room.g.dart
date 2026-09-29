// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_care_room.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HomeCareRoom _$HomeCareRoomFromJson(Map<String, dynamic> json) =>
    _HomeCareRoom(
      id: json['id'] as String,
      name: json['name'] as String,
      kind: $enumDecode(
        _$RoomKindEnumMap,
        json['kind'],
        unknownValue: RoomKind.other,
      ),
      createdBy: json['createdBy'] as String,
      createdAt: const ServerTimestampConverter().fromJson(json['createdAt']),
    );

Map<String, dynamic> _$HomeCareRoomToJson(_HomeCareRoom instance) =>
    <String, dynamic>{
      'name': instance.name,
      'kind': _$RoomKindEnumMap[instance.kind]!,
      'createdBy': instance.createdBy,
      'createdAt': const ServerTimestampConverter().toJson(instance.createdAt),
    };

const _$RoomKindEnumMap = {
  RoomKind.kitchen: 'kitchen',
  RoomKind.lounge: 'lounge',
  RoomKind.dining: 'dining',
  RoomKind.bedroom: 'bedroom',
  RoomKind.kidsRoom: 'kidsRoom',
  RoomKind.bathroom: 'bathroom',
  RoomKind.laundry: 'laundry',
  RoomKind.office: 'office',
  RoomKind.outside: 'outside',
  RoomKind.garage: 'garage',
  RoomKind.other: 'other',
};
