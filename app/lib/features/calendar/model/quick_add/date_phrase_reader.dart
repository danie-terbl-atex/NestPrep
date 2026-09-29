import '../../../../shared/time/calendar_date.dart';
import 'quick_add_sentence.dart';
import 'quick_add_vocabulary.dart';

/// A day found at a place in the sentence, and how many words it took. A day
/// that is not in the calendar — 31 February — is found and marked impossible,
/// never moved to a day that is (calendar ADR-0004).
final class DateMatch {
  const DateMatch(this.date, this.length) : isImpossible = false;
  const DateMatch.impossible(this.length) : date = null, isImpossible = true;

  final CalendarDate? date;
  final int length;
  final bool isImpossible;
}

/// The day the sentence names, if it names one.
final class DateOfEvent {
  const DateOfEvent({this.date, this.isImpossible = false});

  final CalendarDate? date;
  final bool isImpossible;
}

/// Reads days: `today`, `tomorrow`, a weekday, `next Friday`, `in 3 days`,
/// `3 March`, `March 3`, `3/3` (day first — South African English), ISO, and
/// `the 14th`. It never reads a clock; [today] is handed in, so the same
/// sentence on the same day always reads the same.
final class DatePhraseReader {
  DatePhraseReader(this._sentence, {required this.today});

  final QuickAddSentence _sentence;
  final CalendarDate today;

  static final _ordinal = RegExp(r'^(\d{1,2})(st|nd|rd|th)?$');
  static final _slashed = RegExp(r'^(\d{1,2})/(\d{1,2})(?:/(\d{2}|\d{4}))?$');
  static final _dashed = RegExp(r'^(\d{1,2})[-.](\d{1,2})[-.](\d{2}|\d{4})$');
  static final _iso = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$');
  static final _year = RegExp(r'^\d{4}$');
  static final _suffixedOrdinal = RegExp(r'^(\d{1,2})(st|nd|rd|th)$');

  DateOfEvent read() {
    for (var i = 0; i < _sentence.length; i++) {
      final match = dateAt(i);
      if (match == null) continue;
      _sentence
        ..claim(i, match.length)
        ..claimLeading(i, const {'on', 'from', 'starting', 'this'});
      if (match.isImpossible) return const DateOfEvent(isImpossible: true);
      return DateOfEvent(date: match.date);
    }
    return const DateOfEvent();
  }

  /// A day beginning at [index], without claiming it — the repeat reader asks
  /// this for the day after "until".
  DateMatch? dateAt(int index) {
    if (!_sentence.isFree(index)) return null;
    final word = _sentence.word(index);
    if (word == null) return null;
    return _relative(index, word) ??
        _weekday(index, word) ??
        _numeric(word) ??
        _dayThenMonth(index, word) ??
        _monthThenDay(index, word) ??
        _dayOfThisMonth(index, word);
  }

  DateMatch? _relative(int index, String word) {
    switch (word) {
      case 'today' || 'tonight':
        return DateMatch(today, 1);
      case 'tomorrow' || 'tmrw' || 'tmr':
        return DateMatch(today.addDays(1), 1);
    }
    if (word == 'the' &&
        _sentence.word(index + 1) == 'day' &&
        _sentence.word(index + 2) == 'after' &&
        _sentence.word(index + 3) == 'tomorrow') {
      return DateMatch(today.addDays(2), 4);
    }
    if (word == 'day' &&
        _sentence.word(index + 1) == 'after' &&
        _sentence.word(index + 2) == 'tomorrow') {
      return DateMatch(today.addDays(2), 3);
    }
    if (word == 'in') {
      final amount = QuickAddVocabulary.count(_sentence.word(index + 1) ?? '');
      final unit = _sentence.word(index + 2);
      if (amount == null) return null;
      if (unit == 'day' || unit == 'days') {
        return DateMatch(today.addDays(amount), 3);
      }
      if (unit == 'week' || unit == 'weeks') {
        return DateMatch(today.addDays(amount * 7), 3);
      }
    }
    return null;
  }

  /// `Friday` and `this Friday` are the coming Friday, today included; `next
  /// Friday` is the Friday of next week.
  DateMatch? _weekday(int index, String word) {
    if (word == 'next') {
      final weekday = QuickAddVocabulary.weekdays[_sentence.word(index + 1)];
      if (weekday == null) return null;
      return DateMatch(today.weekStart.addDays(7 + weekday - 1), 2);
    }
    final weekday = QuickAddVocabulary.weekdays[word];
    if (weekday == null) return null;
    return DateMatch(nextOnOrAfter(today, weekday), 1);
  }

  DateMatch? _numeric(String word) {
    final iso = _iso.firstMatch(word);
    if (iso != null) {
      return _build(
        int.parse(iso.group(1)!),
        int.parse(iso.group(2)!),
        int.parse(iso.group(3)!),
        1,
      );
    }
    final dayFirst = _slashed.firstMatch(word) ?? _dashed.firstMatch(word);
    if (dayFirst == null) return null;
    final day = int.parse(dayFirst.group(1)!);
    final month = int.parse(dayFirst.group(2)!);
    final yearText = dayFirst.group(3);
    return yearText == null
        ? _withoutYear(day, month, 1)
        : _build(_fullYear(yearText), month, day, 1);
  }

  /// `3 March`, `3rd of March`, `3 Mar 2027`.
  DateMatch? _dayThenMonth(int index, String word) {
    final ordinal = _ordinal.firstMatch(word);
    if (ordinal == null) return null;
    var monthAt = index + 1;
    if (_sentence.word(monthAt) == 'of') monthAt++;
    final month = QuickAddVocabulary.months[_sentence.word(monthAt)];
    if (month == null) return null;
    final day = int.parse(ordinal.group(1)!);
    return _withOptionalYear(day, month, index, monthAt + 1 - index);
  }

  /// `March 3`, `March 3rd 2027`.
  DateMatch? _monthThenDay(int index, String word) {
    final month = QuickAddVocabulary.months[word];
    if (month == null) return null;
    final ordinal = _ordinal.firstMatch(_sentence.word(index + 1) ?? '');
    if (ordinal == null) return null;
    final day = int.parse(ordinal.group(1)!);
    return _withOptionalYear(day, month, index, 2);
  }

  /// `the 14th` — this month, or next month once the 14th has passed.
  DateMatch? _dayOfThisMonth(int index, String word) {
    if (word != 'the') return null;
    final ordinal = _suffixedOrdinal.firstMatch(
      _sentence.word(index + 1) ?? '',
    );
    if (ordinal == null) return null;
    final day = int.parse(ordinal.group(1)!);
    if (day < 1 || day > 31) return const DateMatch.impossible(2);
    for (var months = 0; months <= 2; months++) {
      final total = (today.year * 12) + (today.month - 1) + months;
      final year = total ~/ 12;
      final month = (total % 12) + 1;
      if (day > CalendarDate.daysIn(year, month)) continue;
      final candidate = CalendarDate(year, month, day);
      if (!candidate.isBefore(today)) return DateMatch(candidate, 2);
    }
    return const DateMatch.impossible(2);
  }

  /// A day and a month starting at [start], taking the year after them when
  /// there is one.
  DateMatch _withOptionalYear(int day, int month, int start, int length) {
    final next = _sentence.word(start + length);
    if (next != null && _year.hasMatch(next)) {
      return _build(int.parse(next), month, day, length + 1);
    }
    return _withoutYear(day, month, length);
  }

  /// A day and month with no year: this year, or next once it has passed.
  DateMatch _withoutYear(int day, int month, int length) {
    if (month < 1 || month > 12 || day < 1 || day > 31) {
      return DateMatch.impossible(length);
    }
    final thisYear = today.year;
    if (day <= CalendarDate.daysIn(thisYear, month) &&
        !CalendarDate(thisYear, month, day).isBefore(today)) {
      return DateMatch(CalendarDate(thisYear, month, day), length);
    }
    return _build(thisYear + 1, month, day, length);
  }

  DateMatch _build(int year, int month, int day, int length) {
    if (month < 1 ||
        month > 12 ||
        day < 1 ||
        day > CalendarDate.daysIn(year, month)) {
      return DateMatch.impossible(length);
    }
    return DateMatch(CalendarDate(year, month, day), length);
  }

  static int _fullYear(String text) =>
      text.length == 2 ? 2000 + int.parse(text) : int.parse(text);

  /// The first [weekday] on or after [from].
  static CalendarDate nextOnOrAfter(CalendarDate from, int weekday) =>
      from.addDays((weekday - from.weekday + 7) % 7);
}
