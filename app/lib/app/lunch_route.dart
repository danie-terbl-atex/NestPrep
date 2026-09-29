import 'household_route.dart';
import 'household_shell.dart';

/// Where lunch boxes live in the route table (lunch-box ADR-0004): the lunch
/// tab — the household's home — and, under it, the Sunday prep list and the
/// library, sharing one shell so they share one controller and its listeners
/// (the family profiles' shape). Every one is deep-linkable (`FE-17`).
abstract final class LunchRoute {
  static const prepSegment = 'prep';
  static const librarySegment = 'library';

  static final path = '${HouseholdRoute.path}/${HouseholdTab.lunch.segment}';
  static final prepPath = '$path/$prepSegment';
  static final libraryPath = '$path/$librarySegment';

  static String pathFor(String householdId) =>
      HouseholdRoute.pathFor(householdId, HouseholdTab.lunch);

  static String prepPathFor(String householdId) =>
      '${pathFor(householdId)}/$prepSegment';

  static String libraryPathFor(String householdId) =>
      '${pathFor(householdId)}/$librarySegment';
}
