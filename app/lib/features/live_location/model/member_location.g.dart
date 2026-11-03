// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member_location.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MemberLocation _$MemberLocationFromJson(Map<String, dynamic> json) =>
    _MemberLocation(
      id: json['id'] as String,
      point: const CoordinatesConverter().fromJson(json['point']),
      accuracyMetres: (json['accuracyMetres'] as num).toInt(),
      reportedAt: const ServerTimestampConverter().fromJson(json['reportedAt']),
      sharingUntil: const InstantConverter().fromJson(json['sharingUntil']),
      mode:
          $enumDecodeNullable(
            _$ShareModeEnumMap,
            json['mode'],
            unknownValue: ShareMode.window,
          ) ??
          ShareMode.window,
      batteryPercent: (json['batteryPercent'] as num?)?.toInt(),
      charging: json['charging'] as bool?,
      motion: $enumDecodeNullable(
        _$DeviceMotionEnumMap,
        json['motion'],
        unknownValue: DeviceMotion.unknown,
      ),
    );

Map<String, dynamic> _$MemberLocationToJson(
  _MemberLocation instance,
) => <String, dynamic>{
  'point': const CoordinatesConverter().toJson(instance.point),
  'accuracyMetres': instance.accuracyMetres,
  'reportedAt': const ServerTimestampConverter().toJson(instance.reportedAt),
  'sharingUntil': const InstantConverter().toJson(instance.sharingUntil),
  'mode': _$ShareModeEnumMap[instance.mode]!,
  'batteryPercent': ?instance.batteryPercent,
  'charging': ?instance.charging,
  'motion': ?_$DeviceMotionEnumMap[instance.motion],
};

const _$ShareModeEnumMap = {
  ShareMode.window: 'window',
  ShareMode.continuous: 'continuous',
};

const _$DeviceMotionEnumMap = {
  DeviceMotion.still: 'still',
  DeviceMotion.onFoot: 'onFoot',
  DeviceMotion.cycling: 'cycling',
  DeviceMotion.driving: 'driving',
  DeviceMotion.unknown: 'unknown',
};
