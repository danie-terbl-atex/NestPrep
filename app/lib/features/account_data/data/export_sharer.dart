import 'dart:typed_data';

/// Hands a finished export to the phone — the share sheet, so the person can
/// save it to Files, email it to themselves, or keep it however they like.
abstract interface class ExportSharer {
  /// True when the sheet opened; false when it could not.
  Future<bool> share({required String fileName, required Uint8List bytes});
}
