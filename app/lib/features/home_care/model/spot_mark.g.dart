// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'spot_mark.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SpotMark _$SpotMarkFromJson(Map<String, dynamic> json) => _SpotMark(
  points:
      (json['points'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList() ??
      const <double>[],
);

Map<String, dynamic> _$SpotMarkToJson(_SpotMark instance) => <String, dynamic>{
  'points': instance.points,
};
