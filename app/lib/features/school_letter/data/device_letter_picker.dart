import 'dart:isolate';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/copy/school_letter_copy.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/app_log.dart';
import '../../../shared/media/jpeg_shrinker.dart';
import '../model/letter_file.dart';
import 'letter_picker.dart';

/// `image_picker` for a photo and `file_selector` for a PDF — the platform's
/// own screens, so the app asks for no storage permission of its own.
///
/// A photo leaves as a JPEG whose long edge is at most [maxEdge] and with its
/// metadata stripped (`JpegShrinker`): small enough to send in one call, sharp
/// enough for a newsletter's small print, and without the GPS position of the
/// kitchen table it was taken on. A PDF goes as it is.
final class DeviceLetterPicker implements LetterPicker {
  DeviceLetterPicker([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  static const maxEdge = 2200;
  static const jpegQuality = 82;

  static const _pdfs = XTypeGroup(
    label: SchoolLetterCopy.pdfPickerLabel,
    extensions: ['pdf'],
    mimeTypes: ['application/pdf'],
  );

  @override
  Future<LetterFile?> pick(LetterSource source) async {
    try {
      return switch (source) {
        LetterSource.camera => await _photo(ImageSource.camera),
        LetterSource.photos => await _photo(ImageSource.gallery),
        LetterSource.pdf => await _pdf(),
      };
    } on PlatformException catch (error) {
      AppLog.failure('letter picker', code: error.code, error: error);
      throw const SchoolLetterFailure(SchoolLetterProblem.pickerUnavailable);
    }
  }

  Future<LetterFile?> _photo(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      requestFullMetadata: false,
    );
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    final jpeg = await Isolate.run(() => shrink(bytes));
    if (jpeg == null) {
      throw const SchoolLetterFailure(SchoolLetterProblem.letterNotSupported);
    }
    return LetterFile(bytes: jpeg, kind: LetterKind.jpeg);
  }

  Future<LetterFile?> _pdf() async {
    final file = await openFile(acceptedTypeGroups: const [_pdfs]);
    if (file == null) return null;
    return LetterFile(bytes: await file.readAsBytes(), kind: LetterKind.pdf);
  }

  /// The photo pipeline, on whatever thread calls it; null when the bytes are
  /// not a picture.
  static Uint8List? shrink(Uint8List bytes) =>
      JpegShrinker.shrink(bytes, maxEdge: maxEdge, quality: jpegQuality);
}
