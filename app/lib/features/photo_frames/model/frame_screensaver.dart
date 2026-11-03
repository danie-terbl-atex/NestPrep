import 'package:freezed_annotation/freezed_annotation.dart';

part 'frame_screensaver.freezed.dart';

@Freezed(fromJson: false, toJson: false)
abstract class FrameScreensaver with _$FrameScreensaver {
  const factory FrameScreensaver({
    @Default(0) int idleMinutes,
    @Default(FrameScreensaver.defaultSecondsPerPhoto) int secondsPerPhoto,
  }) = _FrameScreensaver;

  const FrameScreensaver._();

  factory FrameScreensaver.fromJson(Object? json) {
    if (json is! Map) return off;
    final idle = _choiceOf(json['idleMinutes'], idleMinuteChoices);
    if (idle == null || idle == 0) return off;
    return FrameScreensaver(
      idleMinutes: idle,
      secondsPerPhoto:
          _choiceOf(json['secondsPerPhoto'], secondsPerPhotoChoices) ??
          defaultSecondsPerPhoto,
    );
  }

  static const off = FrameScreensaver();
  static const idleMinuteChoices = [0, 1, 2, 5, 10, 15, 30, 60];
  static const secondsPerPhotoChoices = [10, 20, 30, 60];
  static const defaultSecondsPerPhoto = 20;

  bool get isOn => idleMinutes > 0;

  Map<String, Object?> toJson() => {
    'idleMinutes': idleMinutes,
    'secondsPerPhoto': secondsPerPhoto,
  };

  static int? _choiceOf(Object? value, List<int> choices) {
    if (value is! num || value != value.roundToDouble()) return null;
    final whole = value.toInt();
    return choices.contains(whole) ? whole : null;
  }
}

final class FrameScreensaverConverter
    implements JsonConverter<FrameScreensaver, Object?> {
  const FrameScreensaverConverter();

  @override
  FrameScreensaver fromJson(Object? json) => FrameScreensaver.fromJson(json);

  @override
  Object? toJson(FrameScreensaver screensaver) => screensaver.toJson();
}
