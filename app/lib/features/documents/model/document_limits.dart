import '../../../shared/failure/app_failure.dart';

/// What a household may keep, and how much of it.
///
/// **These numbers are enforced in `storage.rules`, not here.** This is the
/// client's copy, and it exists only so that a person is refused before they
/// wait for a 20 MiB upload rather than after — which is the one thing `FE-04`
/// allows a client to do with a rule the server owns. `app/test/features/
/// documents/model/document_limits_match_the_rules_test.dart` reads both rules
/// files and fails the moment the two disagree.
abstract final class DocumentLimits {
  /// 20 MiB. A scanned passport is a few hundred kilobytes; a phone photo of a
  /// lease is two or three megabytes. Twenty is generous and still small
  /// enough that a household on a phone contract can afford to be wrong once.
  static const maxSizeBytes = 20 * 1024 * 1024;

  /// What a household files: a scan or a photo of a piece of paper.
  static const keptContentTypes = <String>{
    'application/pdf',
    'image/jpeg',
    'image/png',
    'image/heic',
    'image/webp',
  };

  /// Which of those the app can render itself. Everything else is handed to
  /// the device (documents ADR-0001).
  static const previewableContentTypes = <String>{
    'image/jpeg',
    'image/png',
    'image/heic',
    'image/webp',
  };

  /// A name somebody typed, for a folder or a document.
  static const nameMaxLength = 80;

  static bool isPreviewable(String contentType) =>
      previewableContentTypes.contains(contentType);

  /// Why this file cannot be kept, or null when it can.
  static DocumentProblem? problemWith({
    required String contentType,
    required int sizeBytes,
  }) {
    if (!keptContentTypes.contains(contentType)) {
      return DocumentProblem.unsupportedType;
    }
    if (sizeBytes <= 0 || sizeBytes > maxSizeBytes) {
      return DocumentProblem.fileTooLarge;
    }
    return null;
  }
}
