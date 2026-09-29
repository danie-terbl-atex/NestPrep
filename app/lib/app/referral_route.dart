import 'household_route.dart';

/// Where *give a month, get a month* lives in the route table (subscriptions
/// ADR-0002): under the household, pushed over whatever led to it, so back
/// returns there (`FE-17`).
abstract final class ReferralRoute {
  static const segment = 'referrals';

  static const path = '${HouseholdRoute.path}/$segment';

  static String pathFor(String householdId) =>
      '/households/$householdId/$segment';
}
