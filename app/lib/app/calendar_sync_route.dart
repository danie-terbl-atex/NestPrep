import 'household_route.dart';

/// Where connected calendars live in the route table (calendar ADR-0003): under
/// the household, reached from the week's header and pushed over it, so back
/// returns to the week (`FE-17`).
abstract final class CalendarSyncRoute {
  static const segment = 'calendars';

  static const path = '${HouseholdRoute.path}/$segment';

  static String pathFor(String householdId) =>
      '/households/$householdId/$segment';
}
