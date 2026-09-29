import 'dart:typed_data';

/// Hands a picture of one week's card to the phone's share sheet (calendar
/// ADR-0006) — behind an interface, because a widget test has no share sheet.
abstract interface class CardImageSharer {
  /// Shares [png] with [text] beside it. Throws
  /// `MentalLoadFailure(shareUnavailable)` when the sheet would not open;
  /// the person backing out of it is not a failure.
  Future<void> share({
    required Uint8List png,
    required String fileName,
    required String text,
  });
}
