import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/documents/model/document_folder.dart';
import 'package:nestprep/features/documents/model/household_document.dart';
import 'package:nestprep/features/documents/state/document_library_controller.dart';
import 'package:nestprep/features/documents/ui/document_folder_screen.dart';
import 'package:nestprep/features/documents/ui/document_library_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_document_tools.dart';
import '../../../support/fake_documents.dart';
import '../../../support/fake_link_opener.dart';
import '../../../support/fake_vault.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';

/// The two sheets, driven through the screens that open them — because a sheet
/// pumped on its own proves nothing about whether anything opens it.
///
/// Taps go through `ensureVisible` first: a tap below the fold of a sheet lands
/// somewhere else entirely, which is a vault lesson and not a theory.

const _folderId = 'f-school';

/// Deliberately not the hint the field shows when it is empty, so a test that
/// looks for the folder's own name cannot match the placeholder instead.
DocumentFolder folder([String name = 'House papers']) =>
    DocumentFolder(id: _folderId, name: name, createdBy: Fixtures.samMemberId);

HouseholdDocument document({
  String uploadedBy = Fixtures.samMemberId,
  String contentType = 'application/pdf',
}) => HouseholdDocument(
  id: 'd1',
  folderId: _folderId,
  name: 'Term letter',
  contentType: contentType,
  sizeBytes: 120000,
  uploadedBy: uploadedBy,
);

void main() {
  late FakeDocumentRepository repository;
  late FakeDocumentStore store;
  late FakeDocumentDirectory directory;
  late DocumentLibraryController controller;

  setUp(() {
    repository = FakeDocumentRepository();
    store = FakeDocumentStore();
    directory = FakeDocumentDirectory();
    controller = DocumentLibraryController(
      documentRepository: repository,
      documentStore: store,
      documentDirectory: directory,
      documentPicker: FakeDocumentPicker(),
      documentOpener: FakeLinkOpener(),
      scanIntake: fakeScanIntake(),
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
      viewerUid: Fixtures.samUid,
      isAdmin: true,
    );
  });

  tearDown(() async {
    controller.dispose();
    await repository.close();
  });

  Future<void> tapOn(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> pumpLibrary(WidgetTester tester) async {
    await pumpScreen(
      tester,
      const DocumentLibraryScreen(),
      providers: [
        ChangeNotifierProvider<DocumentLibraryController>.value(
          value: controller,
        ),
        vaultLockProvider(),
        ...documentToolProviders(),
      ],
    );
    repository.emitFolders([folder()]);
    repository.emitDocuments([document()]);
    await tester.pumpAndSettle();
  }

  Future<void> pumpFolder(WidgetTester tester) async {
    await pumpScreen(
      tester,
      const DocumentFolderScreen(folderId: _folderId),
      providers: [
        ChangeNotifierProvider<DocumentLibraryController>.value(
          value: controller,
        ),
        vaultLockProvider(),
        ...documentToolProviders(),
      ],
    );
    repository.emitFolders([folder()]);
    repository.emitDocuments([document()]);
    await tester.pumpAndSettle();
  }

  group('the folder sheet', () {
    testWidgets('names a new folder and saves it', (tester) async {
      await pumpLibrary(tester);

      await tapOn(tester, find.bySemanticsLabel(AppCopy.documentsAddFolder));
      await tester.enterText(find.byType(TextField), 'Insurance');
      await tester.pumpAndSettle();
      await tapOn(tester, find.text(AppCopy.householdSave));

      expect(repository.createdFolders, ['Insurance']);
    });

    testWidgets('renames one that is already there', (tester) async {
      await pumpLibrary(tester);

      await tapOn(tester, find.bySemanticsLabel(AppCopy.documentsEditFolder));
      expect(find.widgetWithText(TextField, 'House papers'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Kids');
      await tester.pumpAndSettle();
      await tapOn(tester, find.text(AppCopy.householdSave));

      expect(repository.renamedFolders.single.name, 'Kids');
    });

    testWidgets('asks before deleting, and takes no for an answer', (
      tester,
    ) async {
      await pumpLibrary(tester);

      await tapOn(tester, find.bySemanticsLabel(AppCopy.documentsEditFolder));
      await tapOn(tester, find.text(AppCopy.documentsDeleteFolder).last);
      expect(find.text(AppCopy.documentsDeleteFolderConfirm), findsOneWidget);
      await tapOn(tester, find.text(AppCopy.householdCancel));

      expect(directory.deletedFolders, isEmpty);
    });

    testWidgets('deletes through the callable when the answer is yes', (
      tester,
    ) async {
      await pumpLibrary(tester);

      await tapOn(tester, find.bySemanticsLabel(AppCopy.documentsEditFolder));
      await tapOn(tester, find.text(AppCopy.documentsDeleteFolder).last);
      await tapOn(tester, find.text(AppCopy.documentsDeleteFolder).last);

      expect(directory.deletedFolders, [_folderId]);
    });
  });

  group('the document sheet', () {
    testWidgets('renames a document the viewer may change', (tester) async {
      await pumpFolder(tester);

      await tapOn(tester, find.text('Term letter'));
      await tester.enterText(find.byType(TextField).first, 'Term 3 letter');
      await tester.pumpAndSettle();
      await tapOn(tester, find.text(AppCopy.householdSave));

      expect(repository.edited.single.name, 'Term 3 letter');
      expect(repository.edited.single.folderId, _folderId);
    });

    testWidgets('tags a document, and keeps no expiry it was never given', (
      tester,
    ) async {
      // Tags and expiry are phase 2's (documents ADR-0005); a household
      // document written before them has neither, and saving it must not
      // invent a date.
      await pumpFolder(tester);

      await tapOn(tester, find.text('Term letter'));
      await tester.enterText(find.byType(TextField).at(1), 'School');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      await tapOn(tester, find.text(AppCopy.householdSave));

      expect(repository.edited.single.tags, ['School']);
      expect(repository.edited.single.expiresOn, isNull);
    });

    testWidgets('offers the device for a file the app cannot render', (
      tester,
    ) async {
      await pumpFolder(tester);

      await tapOn(tester, find.text('Term letter'));

      expect(find.text(AppCopy.documentsOpenOutside), findsOneWidget);
      expect(find.text(AppCopy.documentsOfflineNote), findsOneWidget);
    });

    testWidgets('deletes the bytes before the row, once asked', (tester) async {
      await pumpFolder(tester);

      await tapOn(tester, find.text('Term letter'));
      await tapOn(tester, find.text(AppCopy.documentsDelete).last);
      await tapOn(tester, find.text(AppCopy.documentsDelete).last);

      expect(store.removedBytes, ['d1']);
      expect(repository.removed, ['d1']);
    });

    testWidgets('shows nobody else the controls the rules would refuse', (
      tester,
    ) async {
      // A helper who did not upload it may read it and nothing else. The rules
      // say the same in both stores; this only stops a button that would be
      // refused (`FE-04`).
      controller.dispose();
      controller = DocumentLibraryController(
        documentRepository: repository,
        documentStore: store,
        documentDirectory: directory,
        documentPicker: FakeDocumentPicker(),
        documentOpener: FakeLinkOpener(),
        scanIntake: fakeScanIntake(),
        householdId: Fixtures.householdId,
        memberId: Fixtures.thandiMemberId,
        viewerUid: Fixtures.thandiUid,
        isAdmin: false,
      );
      await pumpFolder(tester);

      await tapOn(tester, find.text('Term letter'));

      expect(find.text(AppCopy.documentsDelete), findsNothing);
      expect(find.text(AppCopy.householdSave), findsNothing);
      expect(find.text(AppCopy.documentsOpenOutside), findsOneWidget);
    });
  });
}
