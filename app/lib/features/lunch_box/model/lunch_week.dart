import 'package:flutter/foundation.dart';

import '../../../shared/time/calendar_date.dart';

/// One school week, Monday to Friday, named by its ISO-8601 week — the key a
/// lunch plan is filed under (lunch-box ADR-0001) and the week
/// product-analytics counts a plan in.
///
/// A week is a local thing: it is built from a `CalendarDate` that
/// `HouseholdClock` already put in the household's zone (`ENG-21`), and from
/// there it is arithmetic on days.
@immutable
final class LunchWeek implements Comparable<LunchWeek> {
  LunchWeek.of(CalendarDate day) : monday = day.weekStart;

  /// Parses `YYYY-Www`. Throws `FormatException` on anything else, because a
  /// stored key that is not a week is a boundary failure (`ENG-09`).
  factory LunchWeek.parse(String key) {
    final match = _keyPattern.firstMatch(key);
    if (match == null) throw FormatException('expected YYYY-Www', key);
    final year = int.parse(match.group(1)!);
    final week = int.parse(match.group(2)!);
    // 4 January is always in week 1.
    final mondayOfWeekOne = CalendarDate(year, 1, 4).weekStart;
    final parsed = LunchWeek.of(mondayOfWeekOne.addDays((week - 1) * 7));
    if (parsed.key != key) throw FormatException('no such ISO week', key);
    return parsed;
  }

  /// The week somebody plans on [today]: this one on a school day, the next
  /// one from Saturday — Sunday is when next week's boxes are thought about.
  factory LunchWeek.planningFor(CalendarDate today) =>
      today.weekday >= DateTime.saturday
      ? LunchWeek.of(today.addDays(7))
      : LunchWeek.of(today);

  static final _keyPattern = RegExp(r'^(\d{4})-W(\d{2})$');

  /// Monday to Friday. School terms and public holidays are not modelled yet
  /// (lunch-box ADR-0003): a day off is a box nobody fills.
  static const schoolDayCount = 5;

  /// How many weeks back the learning reads (lunch-box ADR-0003).
  static const historyWeeks = 8;

  final CalendarDate monday;

  /// The five school days, Monday first.
  List<CalendarDate> get schoolDays => [
    for (var offset = 0; offset < schoolDayCount; offset++)
      monday.addDays(offset),
  ];

  /// The Sunday before, when the week's prep is done.
  CalendarDate get prepDay => monday.addDays(-1);

  /// The ISO week's own year and number: the year its Thursday falls in.
  int get isoYear => monday.addDays(3).year;

  int get isoNumber {
    final thursday = monday.addDays(3);
    final firstOfYear = CalendarDate(thursday.year, 1, 1);
    return firstOfYear.daysUntil(thursday) ~/ 7 + 1;
  }

  /// `YYYY-Www`, as stored and as analytics reads a week.
  String get key =>
      '${isoYear.toString().padLeft(4, '0')}-W'
      '${isoNumber.toString().padLeft(2, '0')}';

  LunchWeek get next => LunchWeek.of(monday.addDays(7));
  LunchWeek get previous => LunchWeek.of(monday.addDays(-7));

  LunchWeek shift(int weeks) => LunchWeek.of(monday.addDays(weeks * 7));

  /// Whole weeks from this one to [other]; negative when [other] is earlier.
  int weeksUntil(LunchWeek other) => monday.daysUntil(other.monday) ~/ 7;

  /// A school day of this week by ISO weekday, Monday 1 to Friday 5.
  CalendarDate dayOf(int isoWeekday) => monday.addDays(isoWeekday - 1);

  @override
  int compareTo(LunchWeek other) => monday.compareTo(other.monday);

  @override
  bool operator ==(Object other) =>
      other is LunchWeek && other.monday == monday;

  @override
  int get hashCode => monday.hashCode;

  @override
  String toString() => key;
}
