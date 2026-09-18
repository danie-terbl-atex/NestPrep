import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/documents/model/document_folder.dart';
import 'package:nestprep/features/documents/model/document_limits.dart';
import 'package:nestprep/features/documents/model/household_document.dart';
import 'package:nestprep/features/documents/state/document_library_controller.dart';
import 'package:nestprep/features/documents/ui/document_folder_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_documents.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';

const _folderId = 'f-school';

DocumentFolder folder([String name = 'School']) =>
    DocumentFolder(id: _folderId, name: name, createdBy: Fixtures.samMemberId);

HouseholdDocument document({
  String id = 'd1',
  String name = 'Term letter',
  String uploadedBy = Fixtures.thandiMemberId,
}) => HouseholdDocument(
  id: id,
  folderId: _folderId,
  name: name,
  contentType: 'application/pdf',
  sizeBytes: 120000,
  uploadedBy: uploadedBy,
);

void main() {
  late FakeDocumentRepository repository;
  late FakeDocumentStore store;
  late FakeDocumentDirectory directory;
  late FakeDocumentPicker picker;
  late FakeDocumentOpener opener;
  late DocumentLibraryController controller;

  setUp(() {
    repository = FakeDocumentRepository();
    store = FakeDocumentStore();
    directory = FakeDocumentDirectory();
    picker = FakeDocumentPicker();
    opener = FakeDocumentOpener();
    controller = DocumentLibraryController(
      documentRepository: repository,
      documentStore: store,
      documentDirectory: directory,
      documentPicker: picker,
      documentOpener: opener,
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

  Future<void> pump(
    WidgetTester tester, {
    Brightness? brightness,
    double scale = 1,
  }) => pumpScreen(
    tester,
    const DocumentFolderScreen(folderId: _folderId),
    providers: [
      ChangeNotifierProvider<DocumentLibraryController>.value(
        value: controller,
      ),
    ],
    brightness: brightness ?? Brightness.light,
    textScale: scale,
  );

  testWidgets('holds the layout while it loads', (tester) async {
    await pump(tester);
    await tester.pump();

    expect(find.text(AppCopy.documentsFolderEmptyTitle), findsNothing);
  });

  testWidgets(
    'an empty folder says what to do, and the way in is still there',
    (tester) async {
      await pump(tester);
      repository.emitFolders([folder()]);
      repository.emitDocuments([]);
      await tester.pumpAndSettle();

      expect(find.text('School'), findsOneWidget);
      expect(find.text(AppCopy.documentsFolderEmptyTitle), findsOneWidget);
      // The add control lives in the header, outside the view being swapped.
      expect(
        find.bySemanticsLabel(AppCopy.documentsAdd),
        findsOneWidget,
        reason: 'the empty state must not take away the way to fill it',
      );
    },
  );

  testWidgets('a folder that has been deleted underneath says so', (
    tester,
  ) async {
    await pump(tester);
    repository.emitFolders([]);
    repository.emitDocuments([]);
    await tester.pumpAndSettle();

    expect(
      find.text(AppCopy.documentProblem(DocumentProblem.folderNotFound)),
      findsOneWidget,
    );
  });

  testWidgets('shows human copy and a retry when the read fails', (
    tester,
  ) async {
    await pump(tester);
    repository.failDocumentsWith(const UnavailableFailure());
    await tester.pumpAndSettle();

    expect(
      find.text(AppCopy.failure(const UnavailableFailure())),
      findsOneWidget,
    );
    expect(find.text(AppCopy.retry), findsOneWidget);
  });

  testWidgets('lists what is filed, with the size and who put it there', (
    tester,
  ) async {
    await pump(tester);
    repository.emitFolders([folder()]);
    repository.emitDocuments([document()]);
    await tester.pumpAndSettle();

    expect(find.text('Term letter'), findsOneWidget);
    expect(find.textContaining('Thandi Helper'), findsOneWidget);
  });

  testWidgets('an upload shows what is going and offers to stop it', (
    tester,
  ) async {
    await pump(tester);
    repository.emitFolders([folder()]);
    repository.emitDocuments([]);
    await tester.pumpAndSettle();

    final upload = FakeDocumentUpload();
    store.nextUpload = upload;
    picker.next = pickedDocument(name: 'Lease.pdf');
    final adding = controller.addDocument(_folderId);
    await tester.pump();
    await tester.pump();

    expect(find.text('Lease.pdf'), findsOneWidget);
    expect(find.text(AppCopy.documentsStopUpload), findsOneWidget);

    await upload.finish();
    await adding;
    await tester.pumpAndSettle();

    expect(find.text(AppCopy.documentsStopUpload), findsNothing);
  });

  testWidgets('a failed upload says why and offers to try again', (
    tester,
  ) async {
    await pump(tester);
    repository.emitFolders([folder()]);
    repository.emitDocuments([]);
    await tester.pumpAndSettle();

    final upload = FakeDocumentUpload();
    store.nextUpload = upload;
    picker.next = pickedDocument();
    final adding = controller.addDocument(_folderId);
    await tester.pump();
    await upload.fail(const UnavailableFailure());
    await adding;
    await tester.pumpAndSettle();

    expect(
      find.text(AppCopy.failure(const UnavailableFailure())),
      findsOneWidget,
    );
    expect(find.text(AppCopy.retry), findsOneWidget);
    expect(find.textContaining('storage/'), findsNothing);
  });

  testWidgets('a file the rules would refuse is refused before it is sent', (
    tester,
  ) async {
    await pump(tester);
    repository.emitFolders([folder()]);
    repository.emitDocuments([]);
    await tester.pumpAndSettle();

    picker.next = pickedDocument(sizeBytes: DocumentLimits.maxSizeBytes + 1);
    await controller.addDocument(_folderId);
    await tester.pumpAndSettle();

    expect(
      find.text(AppCopy.documentProblem(DocumentProblem.fileTooLarge)),
      findsOneWidget,
    );
    expect(store.uploads, isEmpty);
  });

  testWidgets('renders in dark and at 200% text without overflowing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await pump(tester, brightness: Brightness.dark, scale: 2);
    repository.emitFolders([folder()]);
    repository.emitDocuments([
      document(name: 'Long-stay visa application form'),
    ]);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Long-stay visa application form'), findsOneWidget);
  });
}
