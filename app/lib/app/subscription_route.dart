import 'household_route.dart';

/// Where plan and billing live in the route table (subscriptions ADR-0001):
/// under the household, reached from the household screen and pushed over
/// it, so back returns there (`FE-17`). The paywall is a sheet, not a route:
/// it opens over whatever the person was doing when they reached for a
/// premium feature, and closes back onto it.
abstract final class SubscriptionRoute {
  static const segment = 'plan';

  static const path = '${HouseholdRoute.path}/$segment';

  static String pathFor(String householdId) =>
      '/households/$householdId/$segment';
}
