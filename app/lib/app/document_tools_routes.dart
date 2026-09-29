import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../features/documents/data/document_directory.dart';
import '../features/documents/data/document_share_directory.dart';
import '../features/documents/data/document_share_repository.dart';
import '../features/documents/data/document_store.dart';
import '../features/documents/data/offline_access_check.dart';
import '../features/documents/data/offline_copy_store.dart';
import '../features/documents/data/pdf_page_renderer.dart';
import '../features/documents/data/vault_store.dart';
import '../features/documents/state/document_shares_controller.dart';
import '../features/documents/state/offline_copies_controller.dart';
import '../features/documents/state/offline_copy_source.dart';
import '../features/documents/state/vault_lock_controller.dart';
import '../features/documents/ui/document_shares_screen.dart';
import '../features/documents/ui/offline_copies_screen.dart';
import '../features/documents/ui/vault_gate.dart';
import '../features/household/model/household_view.dart';
import 'documents_route.dart';
import 'household_route.dart';

/// Documents V2's part of the Documents shell (documents ADR-0006, ADR-0007):
/// the offline copies controller, beside the vault lock it follows, and the
/// two screens — Shared links, and Offline copies behind the vaults' gate.
/// Its own file so the shell changes by two lines.
SingleChildWidget offlineCopiesProvider({
  required String householdId,
  required String uid,
}) => ChangeNotifierProvider(
  create: (context) => OfflineCopiesController(
    store: context.read<OfflineCopyStore>(),
    accessCheck: context.read<OfflineAccessCheck>(),
    source: OfflineCopySource(
      documentStore: context.read<DocumentStore>(),
      vaultStore: context.read<VaultStore>(),
      documentDirectory: context.read<DocumentDirectory>(),
      householdId: householdId,
    ),
    pdfPageRenderer: context.read<PdfPageRenderer>(),
    lock: context.read<VaultLockController>(),
    householdId: householdId,
    uid: uid,
  ),
);

/// Before `:folderId`, which would otherwise match both as folder ids.
List<RouteBase> documentToolRoutes({required String viewerUid}) => [
  GoRoute(
    path: DocumentsRoute.sharesPath,
    builder: (context, state) => ChangeNotifierProvider(
      create: (context) => DocumentSharesController(
        repository: context.read<DocumentShareRepository>(),
        directory: context.read<DocumentShareDirectory>(),
        householdId: HouseholdRoute.idFrom(state),
        viewerUid: viewerUid,
        isFamily: context.read<HouseholdView>().permissions.isFamily,
      ),
      child: const DocumentSharesScreen(),
    ),
  ),
  GoRoute(
    path: DocumentsRoute.offlinePath,
    builder: (context, state) =>
        VaultGate(builder: (context) => const OfflineCopiesScreen()),
  ),
];
