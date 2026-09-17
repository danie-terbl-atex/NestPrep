import 'package:flutter/foundation.dart';

/// A day on a calendar, with no time and no zone — what `ENG-21` means by "a
/// local date that crosses a boundary carries the zone it means": the zone is
/// the household's, applied once at the edge by `HouseholdClock`, and from
/// there inward a day is just a day.
///
/// This is the type for a due date, an all-day event, the key of a completion
/// or an exception, and the Monday a week plan is filed under. It is stored as
/// `YYYY-MM-DD` and never as a timestamp.
@immutable
final class CalendarDate implements Comparable<CalendarDate> {
  CalendarDate(int year, int month, int day)
    : this._(DateTime.utc(year, month, day));

  const CalendarDate._(this._midnightUtc);

  /// The day `instant` falls on, read in whatever zone `instant` is already in.
  /// Callers with a UTC instant want `HouseholdClock.dateOf` instead — this one
  /// would give them the day in UTC, which is the wrong day for a third of it.
  factory CalendarDate.fromDateTime(DateTime instant) =>
      CalendarDate(instant.year, instant.month, instant.day);

  /// Parses `YYYY-MM-DD`. Throws `FormatException` on anything else, because a
  /// stored date that is not a date is a boundary failure, not a default
  /// (`ENG-09`).
  factory CalendarDate.parse(String iso) {
    final match = _isoPattern.firstMatch(iso);
    if (match == null) {
      throw FormatException('expected a YYYY-MM-DD calendar date', iso);
    }
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    if (month < 1 || month > 12 || day < 1 || day > daysIn(year, month)) {
      throw FormatException('no such day in the calendar', iso);
    }
    return CalendarDate(year, month, day);
  }

  static final _isoPattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  /// Midnight of this day, held in UTC so that arithmetic on it never crosses a
  /// daylight-saving boundary. It is a carrier for the date, not an instant the
  /// app means anything by.
  final DateTime _midnightUtc;

  int get year => _midnightUtc.year;
  int get month => _midnightUtc.month;
  int get day => _midnightUtc.day;

  /// ISO-8601 weekday: Monday is 1, Sunday is 7.
  int get weekday => _midnightUtc.weekday;

  String get iso =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  CalendarDate addDays(int days) =>
      CalendarDate._(_midnightUtc.add(Duration(days: days)));

  /// The same day-of-month `months` later, or null where that month is too
  /// short — 31 January plus one month is nothing, not 28 February. Monthly
  /// recurrence skips those months rather than silently moving the day
  /// (foundation ADR-0005).
  CalendarDate? addMonthsKeepingDay(int months) {
    final total = (year * 12) + (month - 1) + months;
    final targetYear = total ~/ 12;
    final targetMonth = (total % 12) + 1;
    if (day > daysIn(targetYear, targetMonth)) return null;
    return CalendarDate(targetYear, targetMonth, day);
  }

  /// The Monday of this day's week. The household week starts on Monday
  /// (calendar phase 1).
  CalendarDate get weekStart => addDays(1 - weekday);

  /// Whole days from this date to [other], negative when [other] is earlier.
  int daysUntil(CalendarDate other) =>
      other._midnightUtc.difference(_midnightUtc).inDays;

  bool isBefore(CalendarDate other) => compareTo(other) < 0;
  bool isAfter(CalendarDate other) => compareTo(other) > 0;

  bool isInRange(CalendarDate from, CalendarDate to) =>
      !isBefore(from) && !isAfter(to);

  static int daysIn(int year, int month) =>
      DateTime.utc(year, month + 1, 0).day;

  @override
  int compareTo(CalendarDate other) =>
      _midnightUtc.compareTo(other._midnightUtc);

  @override
  bool operator ==(Object other) =>
      other is CalendarDate && other._midnightUtc == _midnightUtc;

  @override
  int get hashCode => _midnightUtc.hashCode;

  @override
  String toString() => iso;
}
