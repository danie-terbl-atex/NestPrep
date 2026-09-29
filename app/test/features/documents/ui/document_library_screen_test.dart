import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/documents/model/document_folder.dart';
import 'package:nestprep/features/documents/state/document_library_controller.dart';
import 'package:nestprep/features/documents/ui/document_library_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_document_tools.dart';
import '../../../support/fake_documents.dart';
import '../../../support/fake_link_opener.dart';
import '../../../support/fake_vault.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';

DocumentFolder folder(String id, String name) =>
    DocumentFolder(id: id, name: name, createdBy: Fixtures.samMemberId);

void main() {
  late FakeDocumentRepository repository;
  late FakeDocumentStore store;
  late FakeDocumentDirectory directory;
  late FakeDocumentPicker picker;
  late FakeLinkOpener opener;
  late DocumentLibraryController controller;

  void build({bool isAdmin = true}) {
    controller = DocumentLibraryController(
      documentRepository: repository,
      documentStore: store,
      documentDirectory: directory,
      documentPicker: picker,
      documentOpener: opener,
      scanIntake: fakeScanIntake(),
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
      viewerUid: Fixtures.samUid,
      isAdmin: isAdmin,
    );
  }

  setUp(() {
    repository = FakeDocumentRepository();
    store = FakeDocumentStore();
    directory = FakeDocumentDirectory();
    picker = FakeDocumentPicker();
    opener = FakeLinkOpener();
    build();
  });

  tearDown(() async {
    controller.dispose();
    await repository.close();
  });

  Future<void> pump(
    WidgetTester tester, {
    Brightness? brightness,
    double scale = 1,
  }) => pumpScreen(
    tester,
    const DocumentLibraryScreen(),
    providers: [
      ChangeNotifierProvider<DocumentLibraryController>.value(
        value: controller,
      ),
      vaultLockProvider(),
      ...documentToolProviders(),
    ],
    brightness: brightness ?? Brightness.light,
    textScale: scale,
  );

  testWidgets('holds the layout while it loads rather than collapsing', (
    tester,
  ) async {
    await pump(tester);
    await tester.pump();

    expect(find.text(AppCopy.documentsTitle), findsOneWidget);
    expect(find.text(AppCopy.documentsEmptyTitle), findsNothing);
  });

  testWidgets('an admin with no folders is told to make one, and can', (
    tester,
  ) async {
    await pump(tester);
    repository.emitFolders([]);
    repository.emitDocuments([]);
    await tester.pumpAndSettle();

    expect(find.text(AppCopy.documentsEmptyTitle), findsOneWidget);
    expect(find.text(AppCopy.documentsEmptyBody), findsOneWidget);
    // The way in survives the empty state — that is the vault lesson, and the
    // header carries it as well as the empty view.
    expect(find.text(AppCopy.documentsAddFolder), findsWidgets);
  });

  testWidgets('a member with no folders is told whose job it is', (
    tester,
  ) async {
    controller.dispose();
    build(isAdmin: false);
    await pump(tester);
    repository.emitFolders([]);
    repository.emitDocuments([]);
    await tester.pumpAndSettle();

    expect(find.text(AppCopy.documentsEmptyBodyForMembers), findsOneWidget);
    expect(find.text(AppCopy.documentsAddFolder), findsNothing);
  });

  testWidgets('shows human copy and a way back when the read fails', (
    tester,
  ) async {
    await pump(tester);
    repository.failFoldersWith(const PermissionDeniedFailure());
    await tester.pumpAndSettle();

    expect(
      find.text(AppCopy.failure(const PermissionDeniedFailure())),
      findsOneWidget,
    );
    expect(find.text(AppCopy.retry), findsOneWidget);
    expect(find.textContaining('permission-denied'), findsNothing);
  });

  testWidgets('lists the folders with how much is in each', (tester) async {
    await pump(tester);
    repository.emitFolders([
      folder('f-school', 'School'),
      folder('f-h', 'Home'),
    ]);
    repository.emitDocuments([]);
    await tester.pumpAndSettle();

    expect(find.text('School'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text(AppCopy.documentsInFolder(0)), findsNWidgets(2));
  });

  testWidgets('says out loud that the files are not on the phone', (
    tester,
  ) async {
    // Firestore's cache holds the names; Storage has no cache at all, so
    // opening one on a train does not work and the screen does not pretend.
    await pump(tester);
    repository.emitFolders([folder('f-school', 'School')]);
    repository.emitDocuments([]);
    await tester.pumpAndSettle();

    expect(find.text(AppCopy.documentsOfflineNote), findsOneWidget);
  });

  testWidgets('a refused action shows copy, never an error code', (
    tester,
  ) async {
    await pump(tester);
    repository.emitFolders([]);
    repository.emitDocuments([]);
    await tester.pumpAndSettle();

    repository.failWritesWith = const PermissionDeniedFailure();
    await controller.createFolder('School');
    await tester.pumpAndSettle();

    expect(
      find.text(AppCopy.failure(const PermissionDeniedFailure())),
      findsOneWidget,
    );
  });

  testWidgets('renders in dark and at 200% text without overflowing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await pump(tester, brightness: Brightness.dark, scale: 2);
    repository.emitFolders([folder('f-school', 'School reports and letters')]);
    repository.emitDocuments([]);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // Below the vault's way in at this size, and reachable by scrolling.
    await tester.scrollUntilVisible(
      find.text('School reports and letters'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(tester.takeException(), isNull);
    expect(find.text('School reports and letters'), findsOneWidget);
  });
}
