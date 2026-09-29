import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/accounts/state/session_controller.dart';
import '../features/documents/data/document_directory.dart';
import '../features/documents/data/document_opener.dart';
import '../features/documents/data/document_picker.dart';
import '../features/documents/data/document_repository.dart';
import '../features/documents/data/document_store.dart';
import '../features/documents/state/document_library_controller.dart';
import '../features/documents/ui/document_folder_screen.dart';
import '../features/documents/ui/document_library_screen.dart';
import '../features/household/model/household_view.dart';
import 'documents_route.dart';
import 'household_route.dart';
import 'viewer_member.dart';

/// The documents feature's routes under the household shell (documents
/// ADR-0001), in their own file so the route table gains one line.
///
/// A shell of its own, so the folders screen and a folder share one
/// controller and one pair of listeners rather than opening a second set on
/// the way in.
ShellRoute documentsRoutes(SessionController session) => ShellRoute(
  builder: (context, state, child) => ChangeNotifierProvider(
    create: (context) => DocumentLibraryController(
      documentRepository: context.read<DocumentRepository>(),
      documentStore: context.read<DocumentStore>(),
      documentDirectory: context.read<DocumentDirectory>(),
      documentPicker: context.read<DocumentPicker>(),
      documentOpener: context.read<DocumentOpener>(),
      householdId: HouseholdRoute.idFrom(state),
      memberId: viewerMemberIdOf(context),
      viewerUid: session.uidOrEmpty,
      isAdmin: context.read<HouseholdView>().viewerIsAdmin,
    ),
    child: child,
  ),
  routes: [
    GoRoute(
      path: DocumentsRoute.path,
      builder: (context, state) => const DocumentLibraryScreen(),
    ),
    GoRoute(
      path: DocumentsRoute.folderPath,
      builder: (context, state) =>
          DocumentFolderScreen(folderId: DocumentsRoute.folderIdFrom(state)),
    ),
  ],
);
