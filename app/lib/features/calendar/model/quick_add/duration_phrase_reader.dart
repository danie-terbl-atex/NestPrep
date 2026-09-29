import 'quick_add_sentence.dart';
import 'quick_add_vocabulary.dart';

/// Reads how long an event lasts, when the sentence says so: "for 2 hours",
/// "for an hour", "for half an hour", "for 45 min" (calendar ADR-0004). Runs
/// after the repeat reader has taken "for 6 weeks", so a "for" left here is
/// either a duration or somebody's name.
final class DurationPhraseReader {
  DurationPhraseReader(this._sentence);

  final QuickAddSentence _sentence;

  /// "for 2 hours", "for an hour", "for half an hour", "for 45 min".
  int? read() {
    for (var i = 0; i < _sentence.length; i++) {
      if (_sentence.word(i) != 'for' || !_sentence.isFree(i)) continue;
      if (_sentence.word(i + 1) == 'half' &&
          (_sentence.word(i + 2) == 'an' || _sentence.word(i + 2) == 'a') &&
          _isHourWord(_sentence.word(i + 3))) {
        _sentence.claim(i, 4);
        return 30;
      }
      final amount = _amount(_sentence.word(i + 1));
      final unit = _sentence.word(i + 2);
      if (amount == null || unit == null) continue;
      if (_isHourWord(unit)) {
        _sentence.claim(i, 3);
        return (amount * 60).round();
      }
      if (_isMinuteWord(unit)) {
        _sentence.claim(i, 3);
        return amount.round();
      }
    }
    return null;
  }

  static double? _amount(String? word) {
    if (word == null) return null;
    final spelled = QuickAddVocabulary.numbers[word];
    return spelled?.toDouble() ?? double.tryParse(word);
  }

  static bool _isHourWord(String? word) =>
      const {'hour', 'hours', 'hr', 'hrs', 'h'}.contains(word);

  static bool _isMinuteWord(String? word) =>
      const {'minute', 'minutes', 'min', 'mins'}.contains(word);
}
