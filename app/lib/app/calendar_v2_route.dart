import 'household_route.dart';

/// Where calendar V2's two screens live in the route table (calendar
/// ADR-0005, ADR-0006): under the household, pushed over the screen they are
/// opened from, so back returns there (`FE-17`).
abstract final class CalendarV2Route {
  static const letterSegment = 'letter';
  static const sharedWeekSegment = 'shared-week';

  static const letterPath = '${HouseholdRoute.path}/$letterSegment';
  static const sharedWeekPath = '${HouseholdRoute.path}/$sharedWeekSegment';

  static String letterPathFor(String householdId) =>
      '/households/$householdId/$letterSegment';

  static String sharedWeekPathFor(String householdId) =>
      '/households/$householdId/$sharedWeekSegment';
}
