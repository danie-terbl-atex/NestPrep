import 'household_route.dart';

/// Where *Compare shops* lives in the route table: under the household,
/// pushed over the grocery list, so back returns there (`FE-17`,
/// basket-compare ADR-0001).
abstract final class BasketCompareRoute {
  static const segment = 'compare-shops';

  static const path = '${HouseholdRoute.path}/$segment';

  static String pathFor(String householdId) =>
      '/households/$householdId/$segment';
}
