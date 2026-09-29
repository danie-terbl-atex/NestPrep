import 'lunch_route.dart';

/// Where *Plan my week* lives (lunch-box ADR-0011): under the lunch tab,
/// sharing its shell and the board's controller, deep-linkable (`FE-17`).
abstract final class PlanWeekRoute {
  static const segment = 'plan-week';

  static final path = '${LunchRoute.path}/$segment';

  static String pathFor(String householdId) =>
      '${LunchRoute.pathFor(householdId)}/$segment';
}
