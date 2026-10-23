/// Reading one field of a raw Firestore document into a Dart type without a
/// cast (`ENG-09`): each answers null when the field is not that type, so the
/// caller decides whether that drops the document or takes a default.
abstract final class DocumentFields {
  /// Non-empty text, trimmed.
  static String? text(Object? value) => switch (value) {
    final String text when text.trim().isNotEmpty => text.trim(),
    _ => null,
  };

  /// A whole number — Firestore may hand an integer back as `2.0`.
  static int? whole(Object? value) => switch (value) {
    final int number => number,
    final double number when number == number.roundToDouble() => number.toInt(),
    _ => null,
  };

  /// A list whose every entry is non-empty text; null when any entry is not.
  static List<String>? texts(Object? value) {
    if (value is! List<Object?>) return null;
    final texts = [for (final entry in value) ?text(entry)];
    return texts.length == value.length ? texts : null;
  }
}
