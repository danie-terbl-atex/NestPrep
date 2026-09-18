import 'package:flutter/foundation.dart';

import '../../../shared/time/calendar_date.dart';

/// The day of the year somebody was born, and the year when the household knows
/// it (birthdays ADR-0001).
///
/// It is deliberately not a [CalendarDate]: a birthday whose year nobody knows
/// has no year to be a date in, and some households will not know one. That is
/// the same reason foundation ADR-0007 made a day its own type rather than an
/// instant — the type says what the value means.
///
/// Stored in one field, in two ISO-8601 shapes: `YYYY-MM-DD` when the year is
/// known, and the XML-Schema `gMonthDay` form `--MM-DD` when it is not.
@immutable
final class Birthday implements Comparable<Birthday> {
  /// Throws [FormatException] for a month or a day that is not on the calendar.
  /// With no year, 29 February is a real birthday and is accepted — which leap
  /// years it falls on is [occurrenceIn]'s business, not this constructor's.
  factory Birthday({required int month, required int day, int? year}) {
    if (month < 1 || month > _monthsInAYear) {
      throw FormatException('no such month', month);
    }
    if (day < 1 || day > CalendarDate.daysIn(year ?? _aLeapYear, month)) {
      throw FormatException('no such day in that month', day);
    }
    return Birthday._(month: month, day: day, year: year);
  }

  const Birthday._({required this.month, required this.day, this.year});

  /// Parses either stored shape. Throws [FormatException] on anything else —
  /// the converter is where a stored value that is not a birthday is turned
  /// into "no birthday" rather than an error (`BE-10`).
  factory Birthday.parse(String stored) {
    final withYear = _withYear.firstMatch(stored);
    if (withYear != null) {
      return Birthday(
        year: int.parse(withYear.group(1)!),
        month: int.parse(withYear.group(2)!),
        day: int.parse(withYear.group(3)!),
      );
    }
    final withoutYear = _withoutYear.firstMatch(stored);
    if (withoutYear != null) {
      return Birthday(
        month: int.parse(withoutYear.group(1)!),
        day: int.parse(withoutYear.group(2)!),
      );
    }
    throw FormatException('expected YYYY-MM-DD or --MM-DD', stored);
  }

  /// The birthday a [CalendarDate] falls on, with its year kept.
  factory Birthday.on(CalendarDate date) =>
      Birthday(year: date.year, month: date.month, day: date.day);

  static final _withYear = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');
  static final _withoutYear = RegExp(r'^--(\d{2})-(\d{2})$');

  static const _monthsInAYear = 12;

  /// Any leap year does: it is what makes 29 February a valid day of the year
  /// when no birth year says otherwise.
  static const _aLeapYear = 2000;

  final int month;
  final int day;

  /// Null when the household does not know which year.
  final int? year;

  bool get hasYear => year != null;

  String get iso {
    final monthDay =
        '${month.toString().padLeft(2, '0')}-'
        '${day.toString().padLeft(2, '0')}';
    final born = year;
    return born == null
        ? '--$monthDay'
        : '${born.toString().padLeft(4, '0')}-$monthDay';
  }

  /// The day this birthday is kept on in [year].
  ///
  /// 29 February in a year that has none falls back to the 28th rather than
  /// forward to 1 March: it is a February birthday, and moving it into March
  /// puts it in the wrong month on the week strip and in the wrong month when
  /// somebody says which month it is in (birthdays ADR-0001).
  CalendarDate occurrenceIn(int year) {
    final lastOfTheMonth = CalendarDate.daysIn(year, month);
    final kept = day <= lastOfTheMonth ? day : lastOfTheMonth;
    return CalendarDate(year, month, kept);
  }

  /// The age turned on the occurrence in [year], or null when the birth year is
  /// unknown — or when it is in the future, which no picker allows but a
  /// document written elsewhere could still carry.
  int? ageTurningIn(int year) {
    final born = this.year;
    if (born == null) return null;
    final age = year - born;
    return age < 0 ? null : age;
  }

  /// By the day of the year, so a list of them reads as a calendar rather than
  /// as the order the members happen to be in.
  @override
  int compareTo(Birthday other) {
    final byMonth = month.compareTo(other.month);
    return byMonth != 0 ? byMonth : day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) =>
      other is Birthday &&
      other.month == month &&
      other.day == day &&
      other.year == year;

  @override
  int get hashCode => Object.hash(month, day, year);

  @override
  String toString() => iso;
}
