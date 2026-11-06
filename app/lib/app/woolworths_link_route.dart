import 'household_route.dart';

/// Where linking a Woolworths account lives in the route table: under the
/// household, pushed over the screen that asked, so back returns there
/// (`FE-17`). `?return=1` makes the screen go back by itself once linked,
/// for a cart push to carry on.
abstract final class WoolworthsLinkRoute {
  static const segment = 'woolworths';

  static const path = '${HouseholdRoute.path}/$segment';

  static const returnParameter = 'return';

  static String pathFor(String householdId, {bool returnWhenLinked = false}) =>
      '/households/$householdId/$segment'
      '${returnWhenLinked ? '?$returnParameter=1' : ''}';
}
