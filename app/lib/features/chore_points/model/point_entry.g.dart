// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'point_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PointEntry _$PointEntryFromJson(Map<String, dynamic> json) => _PointEntry(
  id: json['id'] as String,
  memberId: json['memberId'] as String,
  delta: (json['delta'] as num).toInt(),
  kind: $enumDecode(
    _$EntryKindEnumMap,
    json['kind'],
    unknownValue: EntryKind.chore,
  ),
  sourceId: json['sourceId'] as String,
  title: json['title'] as String,
  at: const NullableTimestampConverter().fromJson(json['at']),
);

Map<String, dynamic> _$PointEntryToJson(_PointEntry instance) =>
    <String, dynamic>{
      'memberId': instance.memberId,
      'delta': instance.delta,
      'kind': _$EntryKindEnumMap[instance.kind]!,
      'sourceId': instance.sourceId,
      'title': instance.title,
      'at': const NullableTimestampConverter().toJson(instance.at),
    };

const _$EntryKindEnumMap = {
  EntryKind.chore: 'chore',
  EntryKind.choreUndone: 'choreUndone',
  EntryKind.reward: 'reward',
  EntryKind.rewardReturned: 'rewardReturned',
};
