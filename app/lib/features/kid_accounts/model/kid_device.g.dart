// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kid_device.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_KidDevice _$KidDeviceFromJson(Map<String, dynamic> json) => _KidDevice(
  id: json['id'] as String,
  memberId: json['memberId'] as String,
  label: json['label'] as String? ?? '',
  pairedBy: json['pairedBy'] as String,
  pairedAt: const ServerTimestampConverter().fromJson(json['pairedAt']),
);

Map<String, dynamic> _$KidDeviceToJson(_KidDevice instance) =>
    <String, dynamic>{
      'memberId': instance.memberId,
      'label': instance.label,
      'pairedBy': instance.pairedBy,
      'pairedAt': const ServerTimestampConverter().toJson(instance.pairedAt),
    };
