import 'package:go_router/go_router.dart';

import 'household_route.dart';

/// Where family profiles live in the route table: the family, and one person's
/// profile under it, sharing one shell so they share one controller and one
/// pair of listeners (the documents feature's shape). The member id is in the
/// path, so a profile is deep-linkable and back does the obvious thing
/// (`FE-17`).
abstract final class FamilyRoute {
  static const segment = 'family';
  static const memberParameter = 'memberId';

  static const path = '${HouseholdRoute.path}/$segment';
  static const memberPath = '$path/:$memberParameter';

  static String pathFor(String householdId) =>
      '/households/$householdId/$segment';

  static String memberPathFor(String householdId, String memberId) =>
      '${pathFor(householdId)}/$memberId';

  /// The member this route was matched with. Its absence would mean the route
  /// table and this helper disagree, which is our bug and not a person's.
  static String memberIdFrom(GoRouterState state) {
    final id = state.pathParameters[memberParameter];
    if (id == null || id.isEmpty) {
      throw StateError('a profile route matched without a $memberParameter');
    }
    return id;
  }
}
