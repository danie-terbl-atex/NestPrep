// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'synced_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SyncedEvent _$SyncedEventFromJson(Map<String, dynamic> json) => _SyncedEvent(
  id: json['id'] as String,
  connectionId: json['connectionId'] as String,
  provider: $enumDecode(
    _$CalendarProviderEnumMap,
    json['provider'],
    unknownValue: CalendarProvider.ics,
  ),
  memberId: json['memberId'] as String,
  sourceLabel: json['sourceLabel'] as String? ?? '',
  title: json['title'] as String? ?? '',
  date: const CalendarDateConverter().fromJson(json['date']),
  endDate: const CalendarDateConverter().fromJson(json['endDate']),
  startMinute: (json['startMinute'] as num?)?.toInt(),
  endMinute: (json['endMinute'] as num?)?.toInt(),
);

Map<String, dynamic> _$SyncedEventToJson(_SyncedEvent instance) =>
    <String, dynamic>{
      'connectionId': instance.connectionId,
      'provider': _$CalendarProviderEnumMap[instance.provider]!,
      'memberId': instance.memberId,
      'sourceLabel': instance.sourceLabel,
      'title': instance.title,
      'date': const CalendarDateConverter().toJson(instance.date),
      'endDate': const CalendarDateConverter().toJson(instance.endDate),
      'startMinute': instance.startMinute,
      'endMinute': instance.endMinute,
    };

const _$CalendarProviderEnumMap = {
  CalendarProvider.google: 'google',
  CalendarProvider.microsoft: 'microsoft',
  CalendarProvider.ics: 'ics',
};
