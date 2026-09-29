// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'push_token.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PushToken _$PushTokenFromJson(Map<String, dynamic> json) => _PushToken(
  id: json['id'] as String,
  token: json['token'] as String,
  platform: $enumDecode(_$PushPlatformEnumMap, json['platform']),
  updatedAt: const ServerTimestampConverter().fromJson(json['updatedAt']),
);

Map<String, dynamic> _$PushTokenToJson(_PushToken instance) =>
    <String, dynamic>{
      'token': instance.token,
      'platform': _$PushPlatformEnumMap[instance.platform]!,
      'updatedAt': const ServerTimestampConverter().toJson(instance.updatedAt),
    };

const _$PushPlatformEnumMap = {
  PushPlatform.android: 'android',
  PushPlatform.ios: 'ios',
};
