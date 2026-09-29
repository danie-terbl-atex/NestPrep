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

  /// Where everybody is: reached from the household screen, one level further
  /// in than the tabs, because it is about the people rather than the week.
  static const whereSegment = 'where';

  /// The invite step a new household opens with (household ADR-0003).
  static const setupSegment = 'setup';

  /// One kid's, helper's or carer's access, from the people screen.
  static const memberParameter = 'memberId';
  static const accessSegment = '$householdSegment/access/:$memberParameter';

  static String pathFor(String householdId, HouseholdTab tab) =>
      '/households/$householdId/${tab.segment}';

  static String householdPathFor(String householdId) =>
      '/households/$householdId/$householdSegment';

  static String wherePathFor(String householdId) =>
      '/households/$householdId/$whereSegment';

  static String setupPathFor(String householdId) =>
      '/households/$householdId/$setupSegment';

  static String accessPathFor(String householdId, String memberId) =>
      '${householdPathFor(householdId)}/access/$memberId';

  /// The member this access route was matched with.
  static String memberIdFrom(GoRouterState state) {
    final id = state.pathParameters[memberParameter];
    if (id == null || id.isEmpty) {
      throw StateError('an access route matched without a $memberParameter');
    }
    return id;
  }

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
