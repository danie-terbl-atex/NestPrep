import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../features/account_data/data/account_data_gateway.dart';
import '../features/account_data/data/callable_account_data_gateway.dart';
import '../features/account_data/data/export_sharer.dart';
import '../features/account_data/data/platform_export_sharer.dart';
import '../features/account_data/state/account_deletion_controller.dart';
import '../features/account_data/state/account_export_controller.dart';
import '../features/account_data/ui/account_centre_screen.dart';
import '../features/account_data/ui/account_export_screen.dart';
import '../features/account_data/ui/delete_account_screen.dart';
import '../features/accounts/state/session_controller.dart';
import 'legal_routes.dart';

/// The account centre and everything under it — Download my data, Delete my
/// account, and the legal pages (accounts ADR-0005, ADR-0006). Top-level,
/// outside the household shell: none of it is about one household, and a
/// person with no household yet may still read, download or delete.
List<RouteBase> accountRoutes() => [
  GoRoute(
    path: AccountCentreScreen.path,
    builder: (context, state) => const AccountCentreScreen(),
  ),
  GoRoute(
    path: AccountExportScreen.path,
    builder: (context, state) => ChangeNotifierProvider(
      create: (context) => AccountExportController(
        accountDataGateway: context.read<AccountDataGateway>(),
        exportSharer: context.read<ExportSharer>(),
      ),
      child: const AccountExportScreen(),
    ),
  ),
  GoRoute(
    path: DeleteAccountScreen.path,
    builder: (context, state) => ChangeNotifierProvider(
      create: (context) => AccountDeletionController(
        accountDataGateway: context.read<AccountDataGateway>(),
        signOut: context.read<SessionController>().signOut,
      ),
      child: const DeleteAccountScreen(),
    ),
  ),
  ...legalRoutes(),
];

/// Account data's part of the app-wide graph, spread into `appProviders` so
/// the shared file changes by one line.
List<SingleChildWidget> accountDataProviders() => [
  Provider<AccountDataGateway>(
    create: (context) => CallableAccountDataGateway(
      context.read<FirebaseFunctions>(),
      context.read<FirebaseStorage>(),
    ),
  ),
  Provider<ExportSharer>(create: (context) => PlatformExportSharer()),
];

/// Whether a signed-in person may stay on [location] whatever else the router
/// would do with them — no household yet, an address not yet confirmed. The
/// account centre and its pages are always reachable once signed in (both
/// stores require deleting to be; accounts ADR-0006).
bool isAccountLocation(String location) =>
    location == AccountCentreScreen.path ||
    location.startsWith('${AccountCentreScreen.path}/');
