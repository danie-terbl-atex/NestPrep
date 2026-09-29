// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'summary_moment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SummaryMoment _$SummaryMomentFromJson(Map<String, dynamic> json) =>
    _SummaryMoment(
      kind: $enumDecode(
        _$HandoverKindEnumMap,
        json['kind'],
        unknownValue: HandoverKind.note,
      ),
      at: const InstantConverter().fromJson(json['at']),
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
      hasPhoto: json['hasPhoto'] as bool? ?? false,
    );

Map<String, dynamic> _$SummaryMomentToJson(_SummaryMoment instance) =>
    <String, dynamic>{
      'kind': _$HandoverKindEnumMap[instance.kind]!,
      'at': const InstantConverter().toJson(instance.at),
      'note': instance.note,
      'mood': _$HandoverMoodEnumMap[instance.mood],
      'childIds': instance.childIds,
      'hasPhoto': instance.hasPhoto,
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
