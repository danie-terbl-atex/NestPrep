import 'clock_reading.dart';
import 'duration_phrase_reader.dart';
import 'quick_add_sentence.dart';
import 'quick_add_vocabulary.dart';

/// When in the day, as the sentence said it (calendar ADR-0004).
final class TimeOfEvent {
  const TimeOfEvent({
    this.startMinute,
    this.endMinute,
    this.isAllDay = false,
    this.isImpossible = false,
  });

  final int? startMinute;
  final int? endMinute;

  /// "all day" was said. No time at all is all-day too, but says nothing.
  final bool isAllDay;

  /// Something shaped like a time that is not on a clock — `25:00`.
  final bool isImpossible;

  bool get saidSomething => startMinute != null || isAllDay || isImpossible;
}

/// Reads the time out of a sentence: one time or one range, an optional
/// duration, "all day", and the words that say which half of the day.
final class TimePhraseReader {
  TimePhraseReader(this._sentence);

  final QuickAddSentence _sentence;

  static const _defaultDurationMinutes = 60;
  static const _minutesInADay = 24 * 60;
  static const _rangeWords = {'-', '–', 'to', 'until', 'till', 'til'};
  static const _leadWords = {'at', 'from', 'by', 'around'};

  Meridiem? _hint;
  bool _impossible = false;

  TimeOfEvent read() {
    final isAllDay = _readAllDay();
    _hint = _readPartOfDay();
    final range = _readClock();
    final duration = DurationPhraseReader(_sentence).read();
    if (_impossible) return const TimeOfEvent(isImpossible: true);
    if (range == null) return TimeOfEvent(isAllDay: isAllDay);

    final (start, givenEnd) = range;
    final end =
        givenEnd ??
        (start + (duration ?? _defaultDurationMinutes)) % _minutesInADay;
    return TimeOfEvent(startMinute: start, endMinute: end);
  }

  bool _readAllDay() {
    for (var i = 0; i < _sentence.length; i++) {
      final word = _sentence.word(i);
      if (word == 'all-day' || word == 'allday') {
        _sentence.claim(i, 1);
        return true;
      }
      if (word == 'all' && _sentence.word(i + 1) == 'day') {
        _sentence.claim(i, 2);
        return true;
      }
    }
    return false;
  }

  /// "in the morning", "this afternoon", "Friday evening", and "tonight" —
  /// which the date reader claims as a day, so it is only read here. The word
  /// is a hint either way, and it leaves the title only where it was plainly
  /// saying when: "Morning run" keeps its name.
  Meridiem? _readPartOfDay() {
    for (var i = 0; i < _sentence.length; i++) {
      final word = _sentence.word(i);
      final meridiem = switch (word) {
        'morning' => Meridiem.am,
        'afternoon' || 'evening' || 'tonight' => Meridiem.pm,
        _ => null,
      };
      if (meridiem == null) continue;
      if (word != 'tonight' && _saysWhen(i - 1)) {
        _sentence.claim(i, 1);
        if (_sentence.word(i - 1) == 'the') {
          _sentence
            ..claim(i - 1, 1)
            ..claimLeading(i - 1, const {'in'});
        }
        _sentence.claimLeading(i, const {'this'});
      }
      return meridiem;
    }
    return null;
  }

  bool _saysWhen(int index) {
    final word = _sentence.word(index);
    if (word == null) return false;
    return const {'the', 'this', 'tomorrow', 'today'}.contains(word) ||
        QuickAddVocabulary.weekdays.containsKey(word) ||
        QuickAddVocabulary.pluralWeekdays.containsKey(word) ||
        ClockReading.parse(word) != null ||
        ClockReading.meridiemOf(word) != null;
  }

  /// The first time or range in the sentence, as start and optional end.
  (int, int?)? _readClock() {
    for (var i = 0; i < _sentence.length; i++) {
      if (!_sentence.isFree(i)) continue;
      final found = _clockAt(i);
      if (found != null || _impossible) return found;
    }
    return null;
  }

  (int, int?)? _clockAt(int index) {
    final glued = _gluedRangeAt(index);
    if (glued != null) return glued;

    final start = _timeAt(index);
    if (start == null) return null;
    final (startReading, startLength) = start;

    final afterStart = index + startLength;
    if (_rangeWords.contains(_sentence.word(afterStart)) &&
        _sentence.isFree(afterStart)) {
      final end = _timeAt(afterStart + 1);
      if (end != null) {
        final (endReading, endLength) = end;
        _sentence
          ..claim(index, startLength + 1 + endLength)
          ..claimLeading(index, _leadWords);
        return _resolveRange(startReading, endReading);
      }
    }

    // A lone bare number is a time only when a word before it says so: "at 5".
    final isBare = _isBare(_sentence.word(index) ?? '');
    if (isBare &&
        startLength == 1 &&
        !_leadWords.contains(_sentence.word(index - 1))) {
      return null;
    }
    _sentence
      ..claim(index, startLength)
      ..claimLeading(index, _leadWords);
    if (!startReading.isValid) {
      _impossible = true;
      return null;
    }
    return (startReading.toMinutes(hint: _hint), null);
  }

  /// A time starting at [index] and how many words it took: `5pm`, `5 pm`,
  /// `5 o'clock`, `17h30`, `half past 5`, `quarter to 8`, or a bare `5`. A
  /// number followed by a month is a date, not a time: "from 3 March".
  (ClockReading, int)? _timeAt(int index) {
    if (!_sentence.isFree(index)) return null;
    final word = _sentence.word(index);
    if (word == null) return null;

    final spoken = _spokenTime(index);
    if (spoken != null) return spoken;

    final reading = ClockReading.parse(word) ?? _spelledHour(word);
    if (reading == null) return null;
    final next = _sentence.word(index + 1);
    if (QuickAddVocabulary.months.containsKey(next)) return null;

    final meridiem = ClockReading.meridiemOf(next);
    if (meridiem != null && reading.meridiem == null) {
      return (reading.withMeridiem(meridiem), 2);
    }
    if (next == "o'clock" || next == 'oclock') return (reading, 2);
    return (reading, 1);
  }

  /// "half past 5", "quarter past 3", "quarter to 8", with an optional am/pm.
  (ClockReading, int)? _spokenTime(int index) {
    final offset = switch ((_sentence.word(index), _sentence.word(index + 1))) {
      ('half', 'past') => 30,
      ('quarter', 'past') => 15,
      ('quarter', 'to') => -15,
      _ => null,
    };
    if (offset == null) return null;
    final hourWord = _sentence.word(index + 2);
    final hour = hourWord == null ? null : QuickAddVocabulary.count(hourWord);
    if (hour == null || hour < 1 || hour > 12) return null;
    final reading = offset < 0
        ? ClockReading(hour: hour == 1 ? 12 : hour - 1, minute: 60 + offset)
        : ClockReading(hour: hour, minute: offset);
    final meridiem = ClockReading.meridiemOf(_sentence.word(index + 3));
    return meridiem == null
        ? (reading, 3)
        : (reading.withMeridiem(meridiem), 4);
  }

  /// `3-5pm`, `3pm-4:30pm`, `10:30–12` written as one word, with an optional
  /// am/pm after it: "3-5 pm".
  (int, int?)? _gluedRangeAt(int index) {
    final word = _sentence.word(index);
    if (word == null || !_sentence.isFree(index)) return null;
    final parts = word.split(RegExp('[-–]'));
    if (parts.length != 2 || parts.any((part) => part.isEmpty)) return null;
    final start = ClockReading.parse(parts[0]);
    var end = ClockReading.parse(parts[1]);
    if (start == null || end == null) return null;
    var length = 1;
    final meridiem = ClockReading.meridiemOf(_sentence.word(index + 1));
    if (meridiem != null && end.meridiem == null) {
      end = end.withMeridiem(meridiem);
      length = 2;
    }
    _sentence
      ..claim(index, length)
      ..claimLeading(index, _leadWords);
    return _resolveRange(start, end);
  }

  (int, int?)? _resolveRange(ClockReading start, ClockReading end) {
    if (!start.isValid || !end.isValid) {
      _impossible = true;
      return null;
    }
    var first = start;
    // "3-5pm": the pm said once covers both, unless that would put the start
    // after the end — "11-1pm" starts in the morning.
    final endMeridiem = end.meridiem;
    if (first.isAmbiguous && endMeridiem != null) {
      first = first.withMeridiem(endMeridiem);
      if (first.toMinutes() > end.toMinutes()) {
        first = first.withMeridiem(Meridiem.am);
      }
    }
    final startMinute = first.toMinutes(hint: _hint);
    return (startMinute, _endAfter(startMinute, end));
  }

  /// An unmarked end is whichever of its two readings comes first after the
  /// start: "10 to 12" ends at noon, "7 to 9" in the evening ends at 21:00.
  int _endAfter(int startMinute, ClockReading end) {
    if (!end.isAmbiguous) return end.toMinutes();
    final morning = end.toMinutes(hint: Meridiem.am);
    final evening = end.toMinutes(hint: Meridiem.pm);
    if (morning > startMinute) return morning;
    if (evening > startMinute) return evening;
    return morning;
  }

  /// "at five". Only one to twelve: "a" and "an" are numbers to a duration
  /// and never an hour — "at a friend's" is not 1pm.
  static ClockReading? _spelledHour(String word) {
    if (word == 'a' || word == 'an') return null;
    final hour = QuickAddVocabulary.numbers[word];
    return hour == null ? null : ClockReading(hour: hour, minute: 0);
  }

  static bool _isBare(String word) =>
      ClockReading.isBare(word) || _spelledHour(word) != null;
}
