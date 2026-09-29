import '../../../../shared/recurrence/recurrence_rule.dart';
import '../../../../shared/time/calendar_date.dart';
import 'date_phrase_reader.dart';
import 'quick_add_sentence.dart';
import 'quick_add_vocabulary.dart';

/// How a repeat ends, before the first day is known: on a day, after a span
/// ("for 6 weeks"), or after a number of times ("10 times").
sealed class RepeatEnd {
  const RepeatEnd();
}

final class EndsOn extends RepeatEnd {
  const EndsOn(this.date);
  final CalendarDate date;
}

final class EndsAfterSpan extends RepeatEnd {
  const EndsAfterSpan({required this.amount, required this.unitDays});
  final int amount;

  /// Days in one unit; a month is `-1` and counted on the calendar.
  final int unitDays;
}

final class EndsAfterCount extends RepeatEnd {
  const EndsAfterCount(this.count);
  final int count;
}

/// The repeat a sentence asked for, in the shared rule's terms (foundation
/// ADR-0005), with its end still to be pinned to a first day.
final class RepeatOfEvent {
  const RepeatOfEvent({
    required this.frequency,
    this.interval = 1,
    this.weekdays = const [],
    this.end,
    this.isImpossible = false,
  });

  final RecurrenceFrequency frequency;
  final int interval;
  final List<int> weekdays;
  final RepeatEnd? end;

  /// An end that is not a day — "until 31 February".
  final bool isImpossible;
}

/// Reads repeats: a **plural weekday is weekly** ("Tuesdays"), as are `every
/// Tuesday`, a list of weekdays, `weekdays` and `weekends`; `every other
/// Thursday` and `fortnightly` are every two weeks; `daily`, `monthly`, `every
/// 3 days` and friends; and an end — `until 5 March`, `until December`
/// (through that month), `for 6 weeks`, `10 times` (calendar ADR-0004).
final class RepeatPhraseReader {
  RepeatPhraseReader(this._sentence, {required this.dates});

  final QuickAddSentence _sentence;
  final DatePhraseReader dates;

  static const _monthUnitDays = -1;

  RepeatOfEvent? read() {
    final rule = _readRule();
    if (rule == null) return null;
    final weekdays =
        rule.frequency == RecurrenceFrequency.weekly && rule.weekdays.isEmpty
        ? _readOnWeekdays()
        : rule.weekdays;
    final end = _readEnd();
    return RepeatOfEvent(
      frequency: rule.frequency,
      interval: rule.interval,
      weekdays: weekdays,
      end: end,
      isImpossible: _endIsImpossible,
    );
  }

  bool _endIsImpossible = false;

  RepeatOfEvent? _readRule() {
    for (var i = 0; i < _sentence.length; i++) {
      if (!_sentence.isFree(i)) continue;
      final found = _every(i) ?? _adverb(i) ?? _weekdayHabit(i);
      if (found != null) return found;
    }
    return null;
  }

  /// `every day`, `every 2 weeks`, `every other Thursday`, `every weekday`,
  /// `every month`, `every year`.
  RepeatOfEvent? _every(int index) {
    final word = _sentence.word(index);
    if (word != 'every' && word != 'each') return null;
    var at = index + 1;
    var interval = 1;
    final nth = _sentence.word(at);
    final everyNth = QuickAddVocabulary.everyNth[nth];
    final counted = QuickAddVocabulary.count(nth ?? '');
    if (everyNth != null) {
      interval = everyNth;
      at++;
    } else if (counted != null && nth != 'a' && nth != 'an') {
      interval = counted;
      at++;
    }
    final unit = _sentence.word(at);
    final rule = switch (unit) {
      'day' || 'days' => _rule(RecurrenceFrequency.daily, interval),
      'week' || 'weeks' => _rule(RecurrenceFrequency.weekly, interval),
      'month' || 'months' => _rule(RecurrenceFrequency.monthly, interval),
      'year' || 'years' => _rule(RecurrenceFrequency.monthly, interval * 12),
      'weekday' || 'weekdays' => _rule(
        RecurrenceFrequency.weekly,
        interval,
        const [1, 2, 3, 4, 5],
      ),
      'weekend' ||
      'weekends' => _rule(RecurrenceFrequency.weekly, interval, const [6, 7]),
      _ => null,
    };
    if (rule != null) {
      _sentence.claim(index, at + 1 - index);
      return rule;
    }
    final list = _weekdayListAt(at);
    if (list == null) return null;
    final (weekdays, length) = list;
    _sentence.claim(index, at + length - index);
    return _rule(RecurrenceFrequency.weekly, interval, weekdays);
  }

  /// `daily`, `weekly`, `fortnightly`, `monthly`, and the plural `weekdays`
  /// and `weekends`.
  RepeatOfEvent? _adverb(int index) {
    final rule = switch (_sentence.word(index)) {
      'daily' => _rule(RecurrenceFrequency.daily, 1),
      'weekly' => _rule(RecurrenceFrequency.weekly, 1),
      'fortnightly' || 'biweekly' => _rule(RecurrenceFrequency.weekly, 2),
      'monthly' => _rule(RecurrenceFrequency.monthly, 1),
      'yearly' || 'annually' => _rule(RecurrenceFrequency.monthly, 12),
      'weekdays' => _rule(RecurrenceFrequency.weekly, 1, const [1, 2, 3, 4, 5]),
      'weekends' => _rule(RecurrenceFrequency.weekly, 1, const [6, 7]),
      _ => null,
    };
    if (rule == null) return null;
    _sentence
      ..claim(index, 1)
      ..claimLeading(index, const {'on'});
    return rule;
  }

  /// "Tuesdays", "Tuesdays and Thursdays", "Mon, Wed and Fri" — a plural, or
  /// two or more weekdays together, is a habit rather than a day.
  RepeatOfEvent? _weekdayHabit(int index) {
    final list = _weekdayListAt(index);
    if (list == null) return null;
    final (weekdays, length) = list;
    final isPlural = QuickAddVocabulary.pluralWeekdays.containsKey(
      _sentence.word(index),
    );
    if (!isPlural && weekdays.length < 2) return null;
    _sentence
      ..claim(index, length)
      ..claimLeading(index, const {'on'});
    return _rule(RecurrenceFrequency.weekly, 1, weekdays);
  }

  /// "weekly on Tuesday", "every 2 weeks on Mon and Thu".
  List<int> _readOnWeekdays() {
    for (var i = 0; i < _sentence.length; i++) {
      if (_sentence.word(i) != 'on' || !_sentence.isFree(i)) continue;
      final list = _weekdayListAt(i + 1);
      if (list == null) continue;
      final (weekdays, length) = list;
      _sentence.claim(i, length + 1);
      return weekdays;
    }
    return const [];
  }

  /// Weekdays from [index] on, singular or plural, joined by "and", "&" or
  /// the commas the sentence already split on. Null when [index] is not one.
  (List<int>, int)? _weekdayListAt(int index) {
    final weekdays = <int>[];
    var at = index;
    while (_sentence.isFree(at)) {
      final day = _weekdayOf(_sentence.word(at));
      if (day == null) break;
      if (!weekdays.contains(day)) weekdays.add(day);
      at++;
      final joiner = _sentence.word(at);
      if ((joiner == 'and' || joiner == '&') &&
          _weekdayOf(_sentence.word(at + 1)) != null) {
        at++;
      }
    }
    if (weekdays.isEmpty) return null;
    weekdays.sort();
    return (weekdays, at - index);
  }

  static int? _weekdayOf(String? word) =>
      QuickAddVocabulary.weekdays[word] ??
      QuickAddVocabulary.pluralWeekdays[word];

  RepeatEnd? _readEnd() {
    for (var i = 0; i < _sentence.length; i++) {
      if (!_sentence.isFree(i)) continue;
      final end = _until(i) ?? _span(i) ?? _count(i);
      if (end != null) return end;
    }
    return null;
  }

  /// `until 5 March`, `until December`, `until December 2027`.
  RepeatEnd? _until(int index) {
    const words = {'until', 'till', 'til', 'through', 'ending'};
    if (!words.contains(_sentence.word(index))) return null;
    final month = QuickAddVocabulary.months[_sentence.word(index + 1)];
    final afterMonth = _sentence.word(index + 2);
    final dayFollows =
        afterMonth != null &&
        RegExp(r'^\d{1,2}(st|nd|rd|th)?$').hasMatch(afterMonth);
    if (month != null && !dayFollows) {
      final yearWord = afterMonth;
      final year = yearWord != null && RegExp(r'^\d{4}$').hasMatch(yearWord)
          ? int.parse(yearWord)
          : null;
      _sentence.claim(index, year == null ? 2 : 3);
      return EndsOn(_endOfMonth(month, year));
    }
    final match = dates.dateAt(index + 1);
    if (match == null) return null;
    _sentence.claim(index, match.length + 1);
    final date = match.date;
    if (match.isImpossible || date == null) {
      _endIsImpossible = true;
      return null;
    }
    return EndsOn(date);
  }

  /// The last day of [month]: this year's, or next year's once it has passed.
  CalendarDate _endOfMonth(int month, int? year) {
    final today = dates.today;
    final resolvedYear =
        year ?? (month >= today.month ? today.year : today.year + 1);
    return CalendarDate(
      resolvedYear,
      month,
      CalendarDate.daysIn(resolvedYear, month),
    );
  }

  /// `for 6 weeks`, `for 10 days`, `for 3 months`.
  RepeatEnd? _span(int index) {
    if (_sentence.word(index) != 'for') return null;
    final amount = QuickAddVocabulary.count(_sentence.word(index + 1) ?? '');
    if (amount == null || amount < 1) return null;
    final unitDays = switch (_sentence.word(index + 2)) {
      'day' || 'days' => 1,
      'week' || 'weeks' => 7,
      'month' || 'months' => _monthUnitDays,
      _ => null,
    };
    if (unitDays == null) return null;
    _sentence.claim(index, 3);
    return EndsAfterSpan(amount: amount, unitDays: unitDays);
  }

  /// `10 times`, `for 10 times`.
  RepeatEnd? _count(int index) {
    final amount = QuickAddVocabulary.count(_sentence.word(index) ?? '');
    if (amount == null || amount < 1) return null;
    if (_sentence.word(index + 1) != 'times') return null;
    _sentence
      ..claim(index, 2)
      ..claimLeading(index, const {'for'});
    return EndsAfterCount(amount);
  }

  static RepeatOfEvent _rule(
    RecurrenceFrequency frequency,
    int interval, [
    List<int> weekdays = const [],
  ]) => RepeatOfEvent(
    frequency: frequency,
    interval: interval,
    weekdays: weekdays,
  );

  static bool isMonthUnit(int unitDays) => unitDays == _monthUnitDays;
}
