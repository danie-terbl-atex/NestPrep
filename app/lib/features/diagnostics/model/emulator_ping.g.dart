// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'emulator_ping.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EmulatorPing _$EmulatorPingFromJson(Map<String, dynamic> json) =>
    _EmulatorPing(
      id: json['id'] as String,
      sentFrom: json['sentFrom'] as String,
      sentAt: const ServerTimestampConverter().fromJson(json['sentAt']),
    );

Map<String, dynamic> _$EmulatorPingToJson(_EmulatorPing instance) =>
    <String, dynamic>{
      'sentFrom': instance.sentFrom,
      'sentAt': const ServerTimestampConverter().toJson(instance.sentAt),
    };
