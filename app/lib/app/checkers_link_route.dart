import 'household_route.dart';

/// Where linking a Checkers account lives in the route table: under the
/// household, pushed over the grocery list, so back returns there (`FE-17`).
/// `?return=1` makes the screen go back by itself once linked, for *Add to
/// Checkers* to carry on.
abstract final class CheckersLinkRoute {
  static const segment = 'checkers';

  static const path = '${HouseholdRoute.path}/$segment';

  static const returnParameter = 'return';

  static String pathFor(String householdId, {bool returnWhenLinked = false}) =>
      '/households/$householdId/$segment'
      '${returnWhenLinked ? '?$returnParameter=1' : ''}';
}
