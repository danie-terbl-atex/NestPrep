import '../../../shared/format/nest_dates.dart';
import '../../../shared/time/household_clock.dart';

/// A shift's instants as a person in the household reads them: the time on
/// the household's wall clock and the day it falls on (`ENG-21`). One place,
/// so the hub, shift mode and a summary never format a start two ways.
extension HubClock on HouseholdClock {
  /// "14:05".
  String timeOf(DateTime instant) => NestDates.timeOfDay(minutesOfDay(instant));

  /// "Today", "Yesterday", or the date.
  String dayOf(DateTime instant) => NestDates.relative(dateOf(instant), today);
}
