// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DigestChoice _$DigestChoiceFromJson(Map<String, dynamic> json) =>
    _DigestChoice(
      enabled: json['enabled'] as bool? ?? false,
      minute: (json['minute'] as num?)?.toInt() ?? DigestTimes.defaultMinute,
    );

Map<String, dynamic> _$DigestChoiceToJson(_DigestChoice instance) =>
    <String, dynamic>{'enabled': instance.enabled, 'minute': instance.minute};

_QuietHours _$QuietHoursFromJson(Map<String, dynamic> json) => _QuietHours(
  enabled: json['enabled'] as bool? ?? true,
  startMinute: (json['startMinute'] as num?)?.toInt() ?? DigestTimes.quietStart,
  endMinute: (json['endMinute'] as num?)?.toInt() ?? DigestTimes.quietEnd,
);

Map<String, dynamic> _$QuietHoursToJson(_QuietHours instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
      'startMinute': instance.startMinute,
      'endMinute': instance.endMinute,
    };

_NotificationSettings _$NotificationSettingsFromJson(
  Map<String, dynamic> json,
) => _NotificationSettings(
  id: json['id'] as String,
  digest: json['digest'] == null
      ? const DigestChoice()
      : DigestChoice.fromJson(json['digest'] as Map<String, dynamic>),
  categories:
      (json['categories'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as bool),
      ) ??
      const <String, bool>{},
  quietHours: json['quietHours'] == null
      ? const QuietHours()
      : QuietHours.fromJson(json['quietHours'] as Map<String, dynamic>),
  updatedBy: json['updatedBy'] as String,
  updatedAt: const ServerTimestampConverter().fromJson(json['updatedAt']),
);

Map<String, dynamic> _$NotificationSettingsToJson(
  _NotificationSettings instance,
) => <String, dynamic>{
  'digest': instance.digest.toJson(),
  'categories': instance.categories,
  'quietHours': instance.quietHours.toJson(),
  'updatedBy': instance.updatedBy,
  'updatedAt': const ServerTimestampConverter().toJson(instance.updatedAt),
};
