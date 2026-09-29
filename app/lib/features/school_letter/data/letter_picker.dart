import '../model/letter_file.dart';

/// Where a letter comes from: a photo taken now, one already on the phone, or
/// the PDF the school emailed.
enum LetterSource { camera, photos, pdf }

/// The platform's camera, photo library and file picker, behind an interface
/// because a widget test has none of them (calendar ADR-0005).
abstract interface class LetterPicker {
  /// The letter, ready to send — a photo already shrunk and stripped of its
  /// metadata — or null when the person backed out. Throws
  /// `SchoolLetterFailure(pickerUnavailable)` when nothing would open, and
  /// `SchoolLetterFailure(letterNotSupported)` for a file that is not a
  /// picture or a PDF.
  Future<LetterFile?> pick(LetterSource source);
}
