// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lunch_packed_day.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LunchPackedDay _$LunchPackedDayFromJson(Map<String, dynamic> json) =>
    _LunchPackedDay(
      id: json['id'] as String,
      childId: json['childId'] as String,
      date: json['date'] as String,
      week: json['week'] as String,
      itemIds:
          (json['itemIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      by: json['by'] as String,
      at: const ServerTimestampConverter().fromJson(json['at']),
    );

Map<String, dynamic> _$LunchPackedDayToJson(_LunchPackedDay instance) =>
    <String, dynamic>{
      'childId': instance.childId,
      'date': instance.date,
      'week': instance.week,
      'itemIds': instance.itemIds,
      'by': instance.by,
      'at': const ServerTimestampConverter().toJson(instance.at),
    };
