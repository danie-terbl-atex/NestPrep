import 'package:timezone/timezone.dart' as tz;

import 'calendar_date.dart';

/// The one place a UTC instant becomes a day in the household's timezone, and a
/// day in the household's timezone becomes a UTC instant (`ENG-21`, `BE-12`).
///
/// Every household carries an IANA timezone (household ADR-0001). A parent in
/// another country still sees the family's week, not their own, so the zone
/// that matters is the household's and never the device's. Nothing inward of
/// this class knows a zone exists.
final class HouseholdClock {
  HouseholdClock(this.timeZoneName, {DateTime Function()? now})
    : _location = resolveLocation(timeZoneName),
      _now = now ?? DateTime.now;

  /// The zone a household falls back to when its stored name is one this build
  /// of the database does not know — an old document, or a zone renamed since
  /// (`BE-10`). Losing the calendar is worse than showing it an hour out.
  static final tz.Location fallbackLocation = tz.UTC;

  final String timeZoneName;
  final tz.Location _location;
  final DateTime Function() _now;

  static tz.Location resolveLocation(String name) {
    try {
      return tz.getLocation(name);
    } on tz.LocationNotFoundException {
      return fallbackLocation;
    }
  }

  /// The day [instant] falls on where the household lives.
  CalendarDate dateOf(DateTime instant) {
    final local = tz.TZDateTime.from(instant.toUtc(), _location);
    return CalendarDate(local.year, local.month, local.day);
  }

  /// Today, where the household lives.
  CalendarDate get today => dateOf(_now());

  /// This instant, in UTC — what a handover entry logged "now" is stamped
  /// with, from the same clock a test controls (nanny-hub ADR-0002).
  DateTime get now => _now().toUtc();

  /// The instant midnight of [date] begins at where the household lives — the
  /// lower bound of a query for that day.
  DateTime startOfDay(CalendarDate date) =>
      tz.TZDateTime(_location, date.year, date.month, date.day).toUtc();

  /// The instant [date] ends at, exclusive: midnight of the following day.
  DateTime endOfDay(CalendarDate date) => startOfDay(date.addDays(1));

  /// The instant [time] on [date] means where the household lives. Used when a
  /// member picks a wall-clock time for an event; the stored value is the UTC
  /// instant it resolves to (`BE-12`).
  DateTime instantAt(
    CalendarDate date, {
    required int hour,
    required int minute,
  }) => tz.TZDateTime(
    _location,
    date.year,
    date.month,
    date.day,
    hour,
    minute,
  ).toUtc();

  /// The wall-clock time [instant] shows where the household lives, as minutes
  /// since midnight — what a screen renders and a time picker starts from.
  int minutesOfDay(DateTime instant) {
    final local = tz.TZDateTime.from(instant.toUtc(), _location);
    return (local.hour * Duration.minutesPerHour) + local.minute;
  }
}
