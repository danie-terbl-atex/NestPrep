import '../../../../shared/recurrence/recurrence_rule.dart';
import '../../../../shared/time/calendar_date.dart';

/// The plan map's three kinds of room routine (home-care ADR-0004): what the
/// routine is called, how it is grouped and which rule it starts with. The
/// rule is what actually repeats; a parent can change it afterwards.
///
/// The names are stored as they are written here, and
/// `rules/firestore/household/home_care_routines.rules` lists the same ones.
enum RoutineCadence {
  daily,
  weekly,
  deepClean;

  /// The rule a new routine of this cadence starts with: daily is a helper's
  /// working week, weekly is the first day's weekday, and a deep clean comes
  /// round once a month.
  RecurrenceRule ruleFrom(CalendarDate firstDate) => switch (this) {
    RoutineCadence.daily => const RecurrenceRule(
      frequency: RecurrenceFrequency.weekly,
      weekdays: [1, 2, 3, 4, 5],
    ),
    RoutineCadence.weekly => RecurrenceRule(
      frequency: RecurrenceFrequency.weekly,
      weekdays: [firstDate.weekday],
    ),
    RoutineCadence.deepClean => const RecurrenceRule(
      frequency: RecurrenceFrequency.monthly,
    ),
  };
}
