import 'package:go_router/go_router.dart';

import 'household_route.dart';

/// Where the household's documents live in the route table.
///
/// The folders, one folder's contents, the personal vaults, one person's
/// vault, the vault's view log and search — sharing one shell so they share
/// one set of listeners and one vault lock (documents ADR-0001, ADR-0003).
/// Every id is in the path, so each screen is deep-linkable and back does the
/// obvious thing (`FE-17`). The fixed segments are matched before
/// `:folderId`, which would otherwise swallow them.
abstract final class DocumentsRoute {
  static const segment = 'documents';
  static const folderParameter = 'folderId';
  static const memberParameter = 'memberId';

  static const path = '${HouseholdRoute.path}/$segment';
  static const folderPath = '$path/:$folderParameter';
  static const vaultPath = '$path/vault';
  static const vaultPersonPath = '$vaultPath/:$memberParameter';
  static const vaultLogPath = '$path/vault-log';
  static const searchPath = '$path/search';
  static const sharesPath = '$path/shared-links';
  static const offlinePath = '$path/offline';

  /// Search's query parameters: whose documents, and only the ones that need
  /// attention soon.
  static const personQuery = 'person';
  static const soonQuery = 'soon';

  /// `person=household` searches the shared folders only.
  static const householdPerson = 'household';

  static String pathFor(String householdId) =>
      '/households/$householdId/$segment';

  static String folderPathFor(String householdId, String folderId) =>
      '${pathFor(householdId)}/$folderId';

  static String vaultPathFor(String householdId) =>
      '${pathFor(householdId)}/vault';

  static String vaultPersonPathFor(String householdId, String memberId) =>
      '${vaultPathFor(householdId)}/$memberId';

  static String vaultLogPathFor(String householdId) =>
      '${pathFor(householdId)}/vault-log';

  /// Every live link (documents ADR-0006).
  static String sharesPathFor(String householdId) =>
      '${pathFor(householdId)}/shared-links';

  /// What this phone keeps offline, behind the vaults' lock (documents
  /// ADR-0007).
  static String offlinePathFor(String householdId) =>
      '${pathFor(householdId)}/offline';

  static String searchPathFor(
    String householdId, {
    String? person,
    bool expiringSoon = false,
  }) => Uri(
    path: '${pathFor(householdId)}/search',
    queryParameters: {personQuery: ?person, if (expiringSoon) soonQuery: '1'},
  ).toString().replaceFirst(RegExp(r'\?$'), '');

  /// The folder this route was matched with. Its absence would mean the route
  /// table and this helper disagree, which is our bug and not a person's.
  static String folderIdFrom(GoRouterState state) =>
      _parameter(state, folderParameter);

  static String memberIdFrom(GoRouterState state) =>
      _parameter(state, memberParameter);

  static String _parameter(GoRouterState state, String name) {
    final id = state.pathParameters[name];
    if (id == null || id.isEmpty) {
      throw StateError('a documents route matched without a $name');
    }
    return id;
  }
}
