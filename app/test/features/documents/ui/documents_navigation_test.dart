import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/app/documents_route.dart';
import 'package:nestprep/app/household_route.dart';
import 'package:nestprep/features/documents/model/document_folder.dart';
import 'package:nestprep/features/documents/state/document_library_controller.dart';
import 'package:nestprep/features/documents/ui/document_folder_screen.dart';
import 'package:nestprep/features/documents/ui/document_library_screen.dart';
import 'package:nestprep/features/household/state/household_controller.dart';
import 'package:nestprep/features/household/ui/household_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_documents.dart';
import '../../../support/fake_household.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';

/// Two levels of screen hang off the Household screen, and each has to be
/// reachable, deep-linkable, and leavable.
///
/// This is the mistake the household link already made once: a row that
/// *replaced* the location instead of pushing left nothing to pop, and the
/// system back button closed the app (`FE-17`). Asserting on the router's
/// reported location would not catch it — go_router reports the base location
/// either way — so these assert what a person sees and whether there is
/// anywhere to go back to.
void main() {
  late FakeDocumentRepository documents;
  late FakeHouseholdRepository households;
  late FakeHouseholdDirectory householdDirectory;
  late DocumentLibraryController controller;
  late HouseholdController householdController;

  setUp(() {
    documents = FakeDocumentRepository();
    households = FakeHouseholdRepository();
    householdDirectory = FakeHouseholdDirectory();
    controller = DocumentLibraryController(
      documentRepository: documents,
      documentStore: FakeDocumentStore(),
      documentDirectory: FakeDocumentDirectory(),
      documentPicker: FakeDocumentPicker(),
      documentOpener: FakeDocumentOpener(),
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
      viewerUid: Fixtures.samUid,
      isAdmin: true,
    );
    householdController = HouseholdController(
      householdRepository: households,
      householdDirectory: householdDirectory,
      householdId: Fixtures.householdId,
      viewerUid: Fixtures.samUid,
    );
  });

  tearDown(() async {
    controller.dispose();
    householdController.dispose();
    await documents.close();
    await households.close();
  });

  GoRouter routerFrom(String initialLocation) => GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '${HouseholdRoute.path}/${HouseholdRoute.householdSegment}',
        builder: (context, state) => const HouseholdScreen(),
      ),
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

  Future<void> pump(WidgetTester tester, String initialLocation) async {
    await pumpRouter(
      tester,
      router: routerFrom(initialLocation),
      providers: [
        ChangeNotifierProvider<DocumentLibraryController>.value(
          value: controller,
        ),
        ChangeNotifierProvider<HouseholdController>.value(
          value: householdController,
        ),
      ],
    );
    households.emitHousehold(Fixtures.household());
    households.emitMembers([Fixtures.sam]);
    documents.emitFolders([
      const DocumentFolder(
        id: 'f-school',
        name: 'School',
        createdBy: Fixtures.samMemberId,
      ),
    ]);
    documents.emitDocuments([]);
    await tester.pumpAndSettle();
  }

  testWidgets('the documents open over the household, not instead of it', (
    tester,
  ) async {
    await pump(tester, HouseholdRoute.householdPathFor(Fixtures.householdId));
    expect(find.text(AppCopy.householdTitle), findsOneWidget);

    await tester.tap(find.text(AppCopy.documentsOpenLibrary));
    await tester.pumpAndSettle();

    expect(find.text(AppCopy.documentsTitle), findsOneWidget);
    // The whole point: there is somewhere to go back to. Without this, the
    // system back button closes the app.
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
  });

  testWidgets('and going back lands on the household again', (tester) async {
    await pump(tester, HouseholdRoute.householdPathFor(Fixtures.householdId));
    await tester.tap(find.text(AppCopy.documentsOpenLibrary));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text(AppCopy.householdTitle), findsOneWidget);
    expect(find.text(AppCopy.documentsTitle), findsNothing);
  });

  testWidgets('a folder opens over the list, and back lands on the list', (
    tester,
  ) async {
    await pump(tester, DocumentsRoute.pathFor(Fixtures.householdId));

    await tester.tap(find.text('School'));
    await tester.pumpAndSettle();
    expect(find.text(AppCopy.documentsFolderEmptyTitle), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text(AppCopy.documentsTitle), findsOneWidget);
    expect(find.text(AppCopy.documentsFolderEmptyTitle), findsNothing);
  });

  testWidgets('a deep link straight to a folder offers no way back', (
    tester,
  ) async {
    // Nothing pushed it, so a back button would lead nowhere — and one that
    // leads nowhere is worse than none.
    await pump(
      tester,
      DocumentsRoute.folderPathFor(Fixtures.householdId, 'f-school'),
    );

    expect(find.text(AppCopy.documentsFolderEmptyTitle), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsNothing);
  });
}
