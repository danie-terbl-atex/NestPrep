import 'package:flutter/foundation.dart';

import '../../../shared/time/calendar_date.dart';

/// A month as the grid draws it: whole Monday-to-Sunday weeks, from the one
/// the 1st falls in to the one the last day falls in. Five or six of them, so
/// the window is never wider than 42 days (`BE-08`).
@immutable
final class CalendarMonth {
  CalendarMonth.of(CalendarDate date)
    : first = CalendarDate(date.year, date.month, 1);

  final CalendarDate first;

  CalendarDate get last => CalendarDate(
    first.year,
    first.month,
    CalendarDate.daysIn(first.year, first.month),
  );

  CalendarDate get gridStart => first.weekStart;
  CalendarDate get gridEnd => last.weekStart.addDays(6);
  int get gridDays => gridStart.daysUntil(gridEnd) + 1;

  bool contains(CalendarDate date) =>
      date.year == first.year && date.month == first.month;

  CalendarMonth get previous => CalendarMonth.of(first.addDays(-1));
  CalendarMonth get next => CalendarMonth.of(last.addDays(1));

  @override
  bool operator ==(Object other) =>
      other is CalendarMonth && other.first == first;

  @override
  int get hashCode => first.hashCode;

  @override
  String toString() => first.iso.substring(0, 7);
}
