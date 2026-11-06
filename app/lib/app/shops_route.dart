import 'household_route.dart';

/// Where *Your shops* lives in the route table: under the household, because
/// the shop chosen first and who may link are both the household's.
abstract final class ShopsRoute {
  static const segment = 'shops';

  static const path = '${HouseholdRoute.path}/$segment';

  static String pathFor(String householdId) =>
      '/households/$householdId/$segment';
}
