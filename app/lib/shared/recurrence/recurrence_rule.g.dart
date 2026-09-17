// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurrence_rule.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RecurrenceRule _$RecurrenceRuleFromJson(Map<String, dynamic> json) =>
    _RecurrenceRule(
      frequency: $enumDecode(_$RecurrenceFrequencyEnumMap, json['frequency']),
      interval: (json['interval'] as num?)?.toInt() ?? 1,
      weekdays:
          (json['weekdays'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const <int>[],
      until: const NullableCalendarDateConverter().fromJson(json['until']),
    );

Map<String, dynamic> _$RecurrenceRuleToJson(_RecurrenceRule instance) =>
    <String, dynamic>{
      'frequency': _$RecurrenceFrequencyEnumMap[instance.frequency]!,
      'interval': instance.interval,
      'weekdays': instance.weekdays,
      'until': const NullableCalendarDateConverter().toJson(instance.until),
    };

const _$RecurrenceFrequencyEnumMap = {
  RecurrenceFrequency.daily: 'daily',
  RecurrenceFrequency.weekly: 'weekly',
  RecurrenceFrequency.monthly: 'monthly',
};
