import 'package:freezed_annotation/freezed_annotation.dart';

part 'frame_photo.freezed.dart';

@freezed
abstract class FramePhoto with _$FramePhoto {
  const factory FramePhoto({
    required String id,
    String? uploadedByUid,
    DateTime? createdAt,
  }) = _FramePhoto;

  static final idPattern = RegExp(r'^[A-Za-z0-9_-]{8,64}$');
  static const albumLimit = 100;
  static const maxBytes = 1048576;
}

typedef FramePhotoProgress = ({int current, int total});

typedef FramePhotoAddReport = ({int added, int skipped, bool hitLimit});
