import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/accounts/state/session_controller.dart';
import '../features/documents/data/device_lock.dart';
import '../features/documents/data/document_directory.dart';
import '../features/documents/data/document_opener.dart';
import '../features/documents/data/document_picker.dart';
import '../features/documents/data/document_repository.dart';
import '../features/documents/data/document_scanner.dart';
import '../features/documents/data/document_store.dart';
import '../features/documents/data/pdf_page_renderer.dart';
import '../features/documents/data/scan_composer.dart';
import '../features/documents/data/vault_repository.dart';
import '../features/documents/data/vault_store.dart';
import '../features/documents/model/document_search.dart';
import '../features/documents/state/document_library_controller.dart';
import '../features/documents/state/document_search_controller.dart';
import '../features/documents/state/scan_intake.dart';
import '../features/documents/state/vault_controller.dart';
import '../features/documents/state/vault_lock_controller.dart';
import '../features/documents/state/vault_view_log_controller.dart';
import '../features/documents/ui/document_folder_screen.dart';
import '../features/documents/ui/document_library_screen.dart';
import '../features/documents/ui/document_search_screen.dart';
import '../features/documents/ui/vault_gate.dart';
import '../features/documents/ui/vault_home_screen.dart';
import '../features/documents/ui/vault_person_screen.dart';
import '../features/documents/ui/vault_view_log_screen.dart';
import '../features/household/model/household_view.dart';
import '../shared/copy/vault_copy.dart';
import 'documents_route.dart';
import 'household_route.dart';

/// Everything under Documents, in one shell: the household's folders, the
/// personal vaults, their log and search share one library, one vault lock and
/// one vault controller (documents ADR-0001, ADR-0003). Leaving Documents
/// disposes the shell — which is what locks the vaults again.
///
/// The fixed segments come before `:folderId`, which would otherwise match
/// `vault` and `search` as folder ids.
RouteBase documentsShellRoute(SessionController session) => ShellRoute(
  builder: (context, state, child) {
    final view = context.read<HouseholdView>();
    final householdId = HouseholdRoute.idFrom(state);
    final memberId = view.viewerMember?.id ?? '';
    final scanIntake = ScanIntake(
      scanner: context.read<DocumentScanner>(),
      composer: context.read<ScanComposer>(),
    );
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => DocumentLibraryController(
            documentRepository: context.read<DocumentRepository>(),
            documentStore: context.read<DocumentStore>(),
            documentDirectory: context.read<DocumentDirectory>(),
            documentPicker: context.read<DocumentPicker>(),
            documentOpener: context.read<DocumentOpener>(),
            scanIntake: scanIntake,
            householdId: householdId,
            memberId: memberId,
            viewerUid: session.uidOrEmpty,
            isAdmin: view.viewerIsAdmin,
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => VaultLockController(
            deviceLock: context.read<DeviceLock>(),
            reason: VaultCopy.unlockReason,
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => VaultController(
            vaultRepository: context.read<VaultRepository>(),
            vaultStore: context.read<VaultStore>(),
            documentDirectory: context.read<DocumentDirectory>(),
            documentPicker: context.read<DocumentPicker>(),
            pdfPageRenderer: context.read<PdfPageRenderer>(),
            scanIntake: scanIntake,
            lock: context.read<VaultLockController>(),
            householdId: householdId,
            members: view.members,
            memberId: memberId,
            viewerUid: session.uidOrEmpty,
            isAdmin: view.viewerIsAdmin,
          ),
        ),
      ],
      child: child,
    );
  },
  routes: [
    GoRoute(
      path: DocumentsRoute.path,
      builder: (context, state) => const DocumentLibraryScreen(),
    ),
    GoRoute(
      path: DocumentsRoute.searchPath,
      builder: (context, state) => ChangeNotifierProvider(
        create: (context) =>
            DocumentSearchController(initial: _queryFrom(state)),
        child: const DocumentSearchScreen(),
      ),
    ),
    GoRoute(
      path: DocumentsRoute.vaultPath,
      builder: (context, state) =>
          VaultGate(builder: (context) => const VaultHomeScreen()),
    ),
    GoRoute(
      path: DocumentsRoute.vaultPersonPath,
      builder: (context, state) => VaultGate(
        builder: (context) =>
            VaultPersonScreen(memberId: DocumentsRoute.memberIdFrom(state)),
      ),
    ),
    GoRoute(
      path: DocumentsRoute.vaultLogPath,
      builder: (context, state) => VaultGate(
        builder: (context) => ChangeNotifierProvider(
          create: (context) {
            final view = context.read<HouseholdView>();
            return VaultViewLogController(
              vaultRepository: context.read<VaultRepository>(),
              householdId: HouseholdRoute.idFrom(state),
              members: view.members,
              viewerMemberId: view.viewerMember?.id ?? '',
              isAdmin: view.viewerIsAdmin,
            );
          },
          child: const VaultViewLogScreen(),
        ),
      ),
    ),
    GoRoute(
      path: DocumentsRoute.folderPath,
      builder: (context, state) =>
          DocumentFolderScreen(folderId: DocumentsRoute.folderIdFrom(state)),
    ),
  ],
);

/// Search's starting filters, from its link: "expiring soon" from the strip,
/// "household only" from the folders' strip.
DocumentQuery _queryFrom(GoRouterState state) {
  final parameters = state.uri.queryParameters;
  final person = parameters[DocumentsRoute.personQuery];
  return DocumentQuery(
    owner: switch (person) {
      null || '' => OwnerFilter.anyone,
      DocumentsRoute.householdPerson => OwnerFilter.household,
      final memberId => MemberOwner(memberId),
    },
    expiringSoonOnly: parameters[DocumentsRoute.soonQuery] == '1',
  );
}
