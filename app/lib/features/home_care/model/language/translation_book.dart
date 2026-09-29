import 'helper_language.dart';
import 'reviewed_safety_translations.dart';
import 'translated_line.dart';

/// Every line translated so far into one language, and the shipped reviewed
/// lines above them (home-care ADR-0006). A line not in it is read in
/// English until it is.
final class TranslationBook {
  TranslationBook({
    required this.language,
    Map<String, String> machine = const {},
    Map<HelperLanguage, Map<String, String>> reviewed =
        ReviewedSafetyTranslations.shipped,
  }) : _machine = Map.unmodifiable(machine),
       _reviewed = reviewed[language] ?? const {};

  final HelperLanguage language;
  final Map<String, String> _machine;
  final Map<String, String> _reviewed;

  /// [english] as the helper reads it: a reviewed line first, then a machine
  /// one, else the English itself.
  TranslatedLine lineFor(String english) {
    if (!language.needsTranslation) return TranslatedLine.english(english);
    final reviewed = _reviewed[english];
    if (reviewed != null) {
      return TranslatedLine(
        english: english,
        text: reviewed,
        source: TranslationSource.reviewed,
      );
    }
    final machine = _machine[english];
    if (machine != null) {
      return TranslatedLine(
        english: english,
        text: machine,
        source: TranslationSource.machine,
      );
    }
    return TranslatedLine.english(english);
  }

  /// Which of [texts] still need asking for — neither reviewed nor
  /// translated, and not English already.
  List<String> missing(Iterable<String> texts) => language.needsTranslation
      ? [
          for (final text in {...texts})
            if (!_reviewed.containsKey(text) && !_machine.containsKey(text))
              text,
        ]
      : const [];

  /// This book with [translated] added.
  TranslationBook adding(Map<String, String> translated) => TranslationBook(
    language: language,
    machine: {..._machine, ...translated},
    reviewed: {language: _reviewed},
  );
}
