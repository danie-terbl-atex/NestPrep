import 'household_route.dart';
import 'household_shell.dart';

/// Where lunch boxes live in the route table (lunch-box ADR-0004): the lunch
/// tab — the household's home — and, under it, the Sunday prep list, the
/// library, the share screen and *Fill the week*, sharing one shell so they share one controller and its listeners
/// (the family profiles' shape). Every one is deep-linkable (`FE-17`).
abstract final class LunchRoute {
  static const prepSegment = 'prep';
  static const librarySegment = 'library';
  static const shareSegment = 'share';
  static const fillWeekSegment = 'fill-week';

  /// Whose week *Fill the week* fills, as a query parameter.
  static const childQuery = 'child';

  static final path = '${HouseholdRoute.path}/${HouseholdTab.lunch.segment}';
  static final prepPath = '$path/$prepSegment';
  static final libraryPath = '$path/$librarySegment';
  static final sharePath = '$path/$shareSegment';
  static final fillWeekPath = '$path/$fillWeekSegment';

  static String pathFor(String householdId) =>
      HouseholdRoute.pathFor(householdId, HouseholdTab.lunch);

  static String prepPathFor(String householdId) =>
      '${pathFor(householdId)}/$prepSegment';

  static String libraryPathFor(String householdId) =>
      '${pathFor(householdId)}/$librarySegment';

  /// Share the week as a card or a printable planner (lunch-box ADR-0005).
  static String sharePathFor(String householdId) =>
      '${pathFor(householdId)}/$shareSegment';

  /// *Fill the week* for one child, step by step (lunch-box ADR-0020).
  static String fillWeekPathFor(
    String householdId, {
    required String childId,
  }) => Uri(
    path: '${pathFor(householdId)}/$fillWeekSegment',
    queryParameters: {childQuery: childId},
  ).toString();
}
