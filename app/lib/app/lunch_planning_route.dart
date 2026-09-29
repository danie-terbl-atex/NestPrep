import 'lunch_route.dart';

/// Where lunch-box's V2 tools live in the route table (lunch-box ADR-0006
/// to ADR-0008): under the lunch tab, sharing its shell and its controller,
/// each deep-linkable (`FE-17`). A kid device's chooser is its own top-level
/// place beside the kid home.
abstract final class LunchPlanningRoute {
  static const pantrySegment = 'pantry';
  static const budgetSegment = 'budget';
  static const pricesSegment = 'prices';
  static const picksSegment = 'picks';
  static const chooseSegment = 'choose';
  static const childParameter = 'childId';

  static final pantryPath = '${LunchRoute.path}/$pantrySegment';
  static final budgetPath = '${LunchRoute.path}/$budgetSegment';
  static final pricesPath = '$budgetPath/$pricesSegment';
  static final picksPath = '${LunchRoute.path}/$picksSegment';
  static final choosePath =
      '${LunchRoute.path}/$chooseSegment/:$childParameter';

  /// The kid device's chooser (lunch-box ADR-0008).
  static const kidChoosePath = '/kid/lunch';

  static String pantryPathFor(String householdId) =>
      '${LunchRoute.pathFor(householdId)}/$pantrySegment';

  static String budgetPathFor(String householdId) =>
      '${LunchRoute.pathFor(householdId)}/$budgetSegment';

  static String pricesPathFor(String householdId) =>
      '${budgetPathFor(householdId)}/$pricesSegment';

  static String picksPathFor(String householdId) =>
      '${LunchRoute.pathFor(householdId)}/$picksSegment';

  static String choosePathFor(String householdId, String childId) =>
      '${LunchRoute.pathFor(householdId)}/$chooseSegment/$childId';
}
