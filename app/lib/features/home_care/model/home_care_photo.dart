import '../../../shared/failure/app_failure.dart';
import '../../../shared/photos/compressed_photo.dart';
import '../../../shared/photos/jpeg_compressor.dart';
import 'job_photo.dart';

/// What a job's photo may be (home-care ADR-0003). The rules are the
/// authority; `home_care_limits_match_the_rules_test.dart` reads
/// `rules/storage/paths/home_care.rules` and fails when these drift.
abstract final class HomeCarePhoto {
  /// The most the rules let one photo be.
  static const maxBytes = 5 * 1024 * 1024;

  /// The shared pipeline (`ENG-01`), refusing in home care's words.
  static const compressor = JpegCompressor(
    maxBytes: maxBytes,
    unreadable: HomeCareFailure(HomeCareProblem.photoUnreadable),
    tooLarge: HomeCareFailure(HomeCareProblem.photoTooLarge),
  );
}

/// A compressed photo as the job records it beside its bytes.
extension JobPhotoOfCompressed on CompressedPhoto {
  JobPhoto named(String photoId) =>
      JobPhoto(photoId: photoId, width: width, height: height);
}
