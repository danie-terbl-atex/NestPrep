// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'handover_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HandoverEntry _$HandoverEntryFromJson(Map<String, dynamic> json) =>
    _HandoverEntry(
      id: json['id'] as String,
      kind: $enumDecode(
        _$HandoverKindEnumMap,
        json['kind'],
        unknownValue: HandoverKind.note,
      ),
      note: json['note'] as String?,
      mood: $enumDecodeNullable(
        _$HandoverMoodEnumMap,
        json['mood'],
        unknownValue: JsonKey.nullForUndefinedEnumValue,
      ),
      childIds:
          (json['childIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      photoId: json['photoId'] as String?,
      at: const InstantConverter().fromJson(json['at']),
      byMemberId: json['byMemberId'] as String,
      createdAt: const ServerTimestampConverter().fromJson(json['createdAt']),
    );

Map<String, dynamic> _$HandoverEntryToJson(_HandoverEntry instance) =>
    <String, dynamic>{
      'kind': _$HandoverKindEnumMap[instance.kind]!,
      'note': instance.note,
      'mood': _$HandoverMoodEnumMap[instance.mood],
      'childIds': instance.childIds,
      'photoId': instance.photoId,
      'at': const InstantConverter().toJson(instance.at),
      'byMemberId': instance.byMemberId,
      'createdAt': const ServerTimestampConverter().toJson(instance.createdAt),
    };

const _$HandoverKindEnumMap = {
  HandoverKind.meal: 'meal',
  HandoverKind.nap: 'nap',
  HandoverKind.nappy: 'nappy',
  HandoverKind.mood: 'mood',
  HandoverKind.incident: 'incident',
  HandoverKind.medicine: 'medicine',
  HandoverKind.note: 'note',
};

const _$HandoverMoodEnumMap = {
  HandoverMood.happy: 'happy',
  HandoverMood.calm: 'calm',
  HandoverMood.tired: 'tired',
  HandoverMood.upset: 'upset',
  HandoverMood.unwell: 'unwell',
};
