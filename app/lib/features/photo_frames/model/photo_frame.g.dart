// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'photo_frame.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PhotoFrame _$PhotoFrameFromJson(Map<String, dynamic> json) => _PhotoFrame(
  id: json['id'] as String,
  name: json['name'] as String,
  panels: json['panels'] == null
      ? const FramePanels()
      : FramePanels.fromJson(json['panels'] as Map<String, dynamic>),
  screensaver: json['screensaver'] == null
      ? FrameScreensaver.off
      : const FrameScreensaverConverter().fromJson(json['screensaver']),
  groceries: const FrameGroceriesConverter().fromJson(json['groceries']),
  model: json['model'] as String? ?? '',
  linkedBy: json['linkedBy'] as String? ?? '',
  linkedAt: const NullableTimestampConverter().fromJson(json['linkedAt']),
  lastSeenAt: const NullableTimestampConverter().fromJson(json['lastSeenAt']),
  accepts: json['accepts'] == null
      ? PhotoFrame.pageOnly
      : _acceptsFromJson(json['accepts']),
);

Map<String, dynamic> _$PhotoFrameToJson(
  _PhotoFrame instance,
) => <String, dynamic>{
  'name': instance.name,
  'panels': instance.panels.toJson(),
  'screensaver': const FrameScreensaverConverter().toJson(instance.screensaver),
  'groceries': const FrameGroceriesConverter().toJson(instance.groceries),
  'model': instance.model,
  'linkedBy': instance.linkedBy,
  'linkedAt': const NullableTimestampConverter().toJson(instance.linkedAt),
  'lastSeenAt': const NullableTimestampConverter().toJson(instance.lastSeenAt),
};
