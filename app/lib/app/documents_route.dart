import 'package:go_router/go_router.dart';

import 'household_route.dart';

/// Where the household's documents live in the route table.
///
/// Two screens — the folders, and one folder's contents — sharing one shell so
/// they share one controller and one pair of listeners. The folder id is in the
/// path, so a folder is deep-linkable and back does the obvious thing
/// (`FE-17`).
abstract final class DocumentsRoute {
  static const segment = 'documents';
  static const folderParameter = 'folderId';

  static const path = '${HouseholdRoute.path}/$segment';
  static const folderPath = '$path/:$folderParameter';

  static String pathFor(String householdId) =>
      '/households/$householdId/$segment';

  static String folderPathFor(String householdId, String folderId) =>
      '${pathFor(householdId)}/$folderId';

  /// The folder this route was matched with. Its absence would mean the route
  /// table and this helper disagree, which is our bug and not a person's.
  static String folderIdFrom(GoRouterState state) {
    final id = state.pathParameters[folderParameter];
    if (id == null || id.isEmpty) {
      throw StateError('a folder route matched without a $folderParameter');
    }
    return id;
  }
}
