import 'household_route.dart';

/// Where *Connected assistants* lives in the route table (assistants
/// ADR-0001): under the household, pushed over More, so back returns there
/// (`FE-17`).
abstract final class AssistantsRoute {
  static const segment = 'assistants';

  static const path = '${HouseholdRoute.path}/$segment';

  static String pathFor(String householdId) =>
      '/households/$householdId/$segment';
}
