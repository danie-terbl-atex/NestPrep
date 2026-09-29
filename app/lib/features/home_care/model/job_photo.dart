import 'package:freezed_annotation/freezed_annotation.dart';

part 'job_photo.freezed.dart';
part 'job_photo.g.dart';

/// A photo a job names: the Storage object's last segment (`before`, or
/// `after-{revision}`), and its size in pixels — so the photo and the marks
/// over it are laid out before a byte of it has arrived (home-care ADR-0003).
@freezed
abstract class JobPhoto with _$JobPhoto {
  const factory JobPhoto({
    required String photoId,
    required int width,
    required int height,
  }) = _JobPhoto;

  const JobPhoto._();

  factory JobPhoto.fromJson(Map<String, Object?> json) =>
      _$JobPhotoFromJson(json);

  static const beforeId = 'before';

  /// Each hand-in's photo is named for the revision it moves the job to, so
  /// a job sent back and handed in again never overwrites the first one.
  static String afterIdFor(int revision) => 'after-$revision';

  double get aspectRatio => height <= 0 ? 1 : width / height;
}
