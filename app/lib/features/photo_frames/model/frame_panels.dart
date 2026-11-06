import 'package:freezed_annotation/freezed_annotation.dart';

part 'frame_panels.freezed.dart';
part 'frame_panels.g.dart';

@freezed
abstract class FramePanels with _$FramePanels {
  const factory FramePanels({
    @Default(true) bool calendar,
    @Default(true) bool todos,
    @Default(true) bool meals,
    @Default(false) bool lunch,

    /// Missing on a frame linked before it, which is off; a new link turns it
    /// on (photo-frames ADR-0008).
    @Default(false) bool addEvents,
    @Default(false) bool share,
    @Default(false) bool people,
    String? helperMemberId,
  }) = _FramePanels;

  const FramePanels._();

  factory FramePanels.fromJson(Map<String, Object?> json) =>
      _$FramePanelsFromJson(json);

  bool get showsAnything =>
      calendar || todos || meals || lunch || people || helperMemberId != null;
}
