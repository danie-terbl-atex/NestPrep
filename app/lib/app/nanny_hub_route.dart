import 'package:go_router/go_router.dart';

import 'household_route.dart';

/// Where the nanny hub lives in the route table: its home, and every screen
/// under it sharing one shell so they share one controller (nanny-hub
/// ADR-0003). Every id is in the path, so a card, a shift or a summary is
/// deep-linkable and back does the obvious thing (`FE-17`).
abstract final class NannyHubRoute {
  static const segment = 'nanny';
  static const childParameter = 'childId';
  static const shiftParameter = 'shiftId';

  static const path = '${HouseholdRoute.path}/$segment';
  static const childPath = '$path/children/:$childParameter';
  static const emergencyPath = '$path/emergency';
  static const guidePath = '$path/guide';
  static const rulesPath = '$path/rules';
  static const checklistsPath = '$path/checklists';
  static const shiftPath = '$path/shifts/:$shiftParameter';
  static const summaryPath = '$path/summaries/:$shiftParameter';

  static String pathFor(String householdId) =>
      '/households/$householdId/$segment';

  static String childPathFor(String householdId, String childId) =>
      '${pathFor(householdId)}/children/$childId';

  static String emergencyPathFor(String householdId) =>
      '${pathFor(householdId)}/emergency';

  static String guidePathFor(String householdId) =>
      '${pathFor(householdId)}/guide';

  static String rulesPathFor(String householdId) =>
      '${pathFor(householdId)}/rules';

  static String checklistsPathFor(String householdId) =>
      '${pathFor(householdId)}/checklists';

  static String shiftPathFor(String householdId, String shiftId) =>
      '${pathFor(householdId)}/shifts/$shiftId';

  static String summaryPathFor(String householdId, String shiftId) =>
      '${pathFor(householdId)}/summaries/$shiftId';

  /// A parameter this route was matched with. Its absence would mean the
  /// route table and this helper disagree, which is our bug and not a
  /// person's.
  static String parameterFrom(GoRouterState state, String name) {
    final value = state.pathParameters[name];
    if (value == null || value.isEmpty) {
      throw StateError('a nanny hub route matched without a $name');
    }
    return value;
  }
}
