// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'household_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HouseholdEvent _$HouseholdEventFromJson(Map<String, dynamic> json) =>
    _HouseholdEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      note: json['note'] as String?,
      date: const CalendarDateConverter().fromJson(json['date']),
      startMinute: (json['startMinute'] as num?)?.toInt(),
      endMinute: (json['endMinute'] as num?)?.toInt(),
      recurrence: json['recurrence'] == null
          ? null
          : RecurrenceRule.fromJson(json['recurrence'] as Map<String, dynamic>),
      memberIds:
          (json['memberIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      createdBy: json['createdBy'] as String,
      createdAt: const ServerTimestampConverter().fromJson(json['createdAt']),
    );

Map<String, dynamic> _$HouseholdEventToJson(_HouseholdEvent instance) =>
    <String, dynamic>{
      'title': instance.title,
      'note': instance.note,
      'date': const CalendarDateConverter().toJson(instance.date),
      'startMinute': instance.startMinute,
      'endMinute': instance.endMinute,
      'recurrence': instance.recurrence?.toJson(),
      'memberIds': instance.memberIds,
      'createdBy': instance.createdBy,
      'createdAt': const ServerTimestampConverter().toJson(instance.createdAt),
    };
