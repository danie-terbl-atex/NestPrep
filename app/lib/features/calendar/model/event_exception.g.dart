// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_exception.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EventException _$EventExceptionFromJson(Map<String, dynamic> json) =>
    _EventException(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      occurrenceDate: const CalendarDateConverter().fromJson(
        json['occurrenceDate'],
      ),
      skippedBy: json['skippedBy'] as String,
      skippedAt: const ServerTimestampConverter().fromJson(json['skippedAt']),
    );

Map<String, dynamic> _$EventExceptionToJson(_EventException instance) =>
    <String, dynamic>{
      'eventId': instance.eventId,
      'occurrenceDate': const CalendarDateConverter().toJson(
        instance.occurrenceDate,
      ),
      'skippedBy': instance.skippedBy,
      'skippedAt': const ServerTimestampConverter().toJson(instance.skippedAt),
    };
