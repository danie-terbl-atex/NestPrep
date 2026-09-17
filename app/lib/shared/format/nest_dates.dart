import 'package:intl/intl.dart';

import '../copy/app_copy.dart';
import '../time/calendar_date.dart';

/// Every date a person reads is formatted here (`FE-19`, `ENG-21`). The
/// household's timezone was already applied by `HouseholdClock`; by the time a
/// date reaches this file it is just a day.
abstract final class NestDates {
  static final _dayAndMonth = DateFormat('EEE d MMM');
  static final _dayMonthYear = DateFormat('EEE d MMM yyyy');
  static final _monthAndYear = DateFormat('MMMM yyyy');
  static final _weekdayOnly = DateFormat('EEE');
  static final _dayOnly = DateFormat('d');

  /// "Today", "Yesterday", "Tomorrow", or the date — because a household reads
  /// a list of days, not a list of dates.
  static String relative(CalendarDate date, CalendarDate today) {
    final days = today.daysUntil(date);
    return switch (days) {
      0 => AppCopy.dateToday,
      1 => AppCopy.dateTomorrow,
      -1 => AppCopy.dateYesterday,
      _ => full(date, today),
    };
  }

  /// A day that sits in a column of consecutive days — a week of meal cards, a
  /// todo list grouped by day. Always the date, never "Yesterday".
  ///
  /// `relative` is right for a date on its own, where "Today" is warmer and
  /// shorter than "Fri 18 Sep". It is wrong in a run of days: one row saying
  /// *Yesterday* between rows saying *Mon 14 Sep* and *Wed 16 Sep* reads as two
  /// labelling systems at once, and the eye stops being able to scan the
  /// column. Which day is today is carried by the card's own tint instead, so
  /// nothing is lost by being consistent here.
  static String dayInARun(CalendarDate date, CalendarDate today) =>
      full(date, today);

  /// The date, with the year only when it is not this one.
  static String full(CalendarDate date, CalendarDate today) =>
      date.year == today.year
      ? _dayAndMonth.format(_asDateTime(date))
      : _dayMonthYear.format(_asDateTime(date));

  static String monthAndYear(CalendarDate date) =>
      _monthAndYear.format(_asDateTime(date));

  static String weekday(CalendarDate date) =>
      _weekdayOnly.format(_asDateTime(date));

  static String dayOfMonth(CalendarDate date) =>
      _dayOnly.format(_asDateTime(date));

  /// A wall-clock time, from minutes since midnight in the household's zone.
  static String timeOfDay(int minutesOfDay) {
    final hour = minutesOfDay ~/ 60;
    final minute = minutesOfDay % 60;
    return '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
  }

  /// The week a Monday starts, as a person says it: "15 – 21 Sep".
  static String weekRange(CalendarDate monday) {
    final sunday = monday.addDays(6);
    final start = monday.month == sunday.month
        ? _dayOnly.format(_asDateTime(monday))
        : DateFormat('d MMM').format(_asDateTime(monday));
    final end = DateFormat('d MMM').format(_asDateTime(sunday));
    return '$start – $end';
  }

  /// `intl` formats a `DateTime`, and a `CalendarDate` is a day with no zone —
  /// so it is handed a UTC midnight, which every formatter here reads as the
  /// day itself and never as an instant.
  static DateTime _asDateTime(CalendarDate date) =>
      DateTime.utc(date.year, date.month, date.day);
}
