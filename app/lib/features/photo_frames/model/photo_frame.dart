import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/nullable_timestamp_converter.dart';
import 'frame_groceries.dart';
import 'frame_panels.dart';
import 'frame_screensaver.dart';

part 'photo_frame.freezed.dart';
part 'photo_frame.g.dart';

@freezed
abstract class PhotoFrame with _$PhotoFrame {
  const factory PhotoFrame({
    @JsonKey(includeToJson: false) required String id,
    required String name,
    @Default(FramePanels()) FramePanels panels,
    @FrameScreensaverConverter()
    @Default(FrameScreensaver.off)
    FrameScreensaver screensaver,
    @FrameGroceriesConverter() FrameGroceries? groceries,
    @Default('') String model,
    @Default('') String linkedBy,
    @NullableTimestampConverter() DateTime? linkedAt,
    @NullableTimestampConverter() DateTime? lastSeenAt,
    @JsonKey(fromJson: _acceptsFromJson, includeToJson: false)
    @Default(PhotoFrame.pageOnly)
    List<String> accepts,
  }) = _PhotoFrame;

  const PhotoFrame._();

  factory PhotoFrame.fromJson(Map<String, Object?> json) =>
      _$PhotoFrameFromJson(json);

  static const quietAfter = Duration(hours: 1);
  static const pageOnly = ['page'];
  static const recipeKind = 'recipe';

  bool get opensRecipes => accepts.contains(recipeKind);

  bool isQuietAt(DateTime now) {
    final seen = lastSeenAt ?? linkedAt;
    return seen != null && now.difference(seen) > quietAfter;
  }
}

List<String> _acceptsFromJson(Object? json) => switch (json) {
  List() when json.every((kind) => kind is String) => List<String>.unmodifiable(
    json,
  ),
  _ => PhotoFrame.pageOnly,
};
