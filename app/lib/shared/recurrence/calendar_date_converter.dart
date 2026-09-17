import 'package:json_annotation/json_annotation.dart';

import '../time/calendar_date.dart';

/// A `CalendarDate` stored as `YYYY-MM-DD` (`ENG-21`): a due date, an all-day
/// event's day, the key of a completion. Never a timestamp — a timestamp for a
/// day is ambiguous the moment two members are in different zones.
class CalendarDateConverter implements JsonConverter<CalendarDate, Object?> {
  const CalendarDateConverter();

  @override
  CalendarDate fromJson(Object? json) => switch (json) {
    final String iso => CalendarDate.parse(iso),
    _ => throw FormatException('expected a YYYY-MM-DD calendar date', json),
  };

  @override
  Object toJson(CalendarDate value) => value.iso;
}

/// The same, for a field that may legitimately be absent.
class NullableCalendarDateConverter
    implements JsonConverter<CalendarDate?, Object?> {
  const NullableCalendarDateConverter();

  @override
  CalendarDate? fromJson(Object? json) =>
      json == null ? null : const CalendarDateConverter().fromJson(json);

  @override
  Object? toJson(CalendarDate? value) => value?.iso;
}
