import 'package:go_router/go_router.dart';

import 'household_shell.dart';

/// The household id lives in the path, so every screen under it is
/// deep-linkable, back does the obvious thing, and switching household is a
/// navigation that drops the old listeners (`FE-17`, foundation ADR-0006).
abstract final class HouseholdRoute {
  static const parameter = 'householdId';

  /// The shell every household screen lives under.
  static const path = '/households/:$parameter';

  /// Managing people: reached from a tab's header, not from the bottom bar.
  static const householdSegment = 'household';

  static String pathFor(String householdId, HouseholdTab tab) =>
      '/households/$householdId/${tab.segment}';

  static String householdPathFor(String householdId) =>
      '/households/$householdId/$householdSegment';

  /// Where a household opens: the week, because that is the question the app
  /// exists to answer.
  static String homeFor(String householdId) =>
      pathFor(householdId, HouseholdTab.week);

  /// The id this route was matched with. Its absence would mean the route table
  /// and this helper disagree, which is our bug and not a person's.
  static String idFrom(GoRouterState state) {
    final id = state.pathParameters[parameter];
    if (id == null || id.isEmpty) {
      throw StateError('a household route matched without a $parameter');
    }
    return id;
  }
}
