// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custody_schedule.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CustodyBlock _$CustodyBlockFromJson(Map<String, dynamic> json) =>
    _CustodyBlock(
      side: $enumDecode(_$CustodySideEnumMap, json['side']),
      weekOffset: (json['weekOffset'] as num).toInt(),
      weekdays: (json['weekdays'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
    );

Map<String, dynamic> _$CustodyBlockToJson(_CustodyBlock instance) =>
    <String, dynamic>{
      'side': _$CustodySideEnumMap[instance.side]!,
      'weekOffset': instance.weekOffset,
      'weekdays': instance.weekdays,
    };

const _$CustodySideEnumMap = {CustodySide.a: 'a', CustodySide.b: 'b'};

_CustodySchedule _$CustodyScheduleFromJson(Map<String, dynamic> json) =>
    _CustodySchedule(
      pattern: $enumDecode(
        _$CustodyPatternEnumMap,
        json['pattern'],
        unknownValue: CustodyPattern.custom,
      ),
      startsOn: const CalendarDateConverter().fromJson(json['startsOn']),
      cycleWeeks: (json['cycleWeeks'] as num).toInt(),
      blocks: (json['blocks'] as List<dynamic>)
          .map((e) => CustodyBlock.fromJson(e as Map<String, dynamic>))
          .toList(),
      handoverMinute: (json['handoverMinute'] as num?)?.toInt(),
    );

Map<String, dynamic> _$CustodyScheduleToJson(_CustodySchedule instance) =>
    <String, dynamic>{
      'pattern': _$CustodyPatternEnumMap[instance.pattern]!,
      'startsOn': const CalendarDateConverter().toJson(instance.startsOn),
      'cycleWeeks': instance.cycleWeeks,
      'blocks': instance.blocks.map((e) => e.toJson()).toList(),
      'handoverMinute': instance.handoverMinute,
    };

const _$CustodyPatternEnumMap = {
  CustodyPattern.alternatingWeeks: 'alternatingWeeks',
  CustodyPattern.twoTwoThree: 'twoTwoThree',
  CustodyPattern.everyOtherWeekend: 'everyOtherWeekend',
  CustodyPattern.custom: 'custom',
};
