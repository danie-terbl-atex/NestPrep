import 'package:flutter/foundation.dart';

/// Where the words a helper reads came from (home-care ADR-0006).
enum TranslationSource {
  /// Nothing to translate: she reads English, or it is not translated yet.
  english,

  /// Cloud Translation — badged, with the English a tap or a line away.
  machine,

  /// A fluent speaker checked it against the English.
  reviewed,
}

/// One English line as the helper reads it: the words, and where they came
/// from, with the English kept beside so a safety line never stands alone.
@immutable
final class TranslatedLine {
  const TranslatedLine({
    required this.english,
    required this.text,
    required this.source,
  });

  const TranslatedLine.english(this.english)
    : text = english,
      source = TranslationSource.english;

  final String english;
  final String text;
  final TranslationSource source;

  bool get isTranslated => source != TranslationSource.english;

  @override
  bool operator ==(Object other) =>
      other is TranslatedLine &&
      other.english == english &&
      other.text == text &&
      other.source == source;

  @override
  int get hashCode => Object.hash(english, text, source);
}
