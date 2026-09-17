import 'package:go_router/go_router.dart';

/// The household id lives in the path, so every screen under it is
/// deep-linkable and switching household is a navigation (`FE-17`).
abstract final class HouseholdRoute {
  static const parameter = 'householdId';
  static const path = '/households/:$parameter';

  static String pathFor(String householdId) => '/households/$householdId';

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
