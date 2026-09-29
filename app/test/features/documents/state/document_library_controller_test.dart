import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/documents/model/document_folder.dart';
import 'package:nestprep/features/documents/model/document_library.dart';
import 'package:nestprep/features/documents/model/document_limits.dart';
import 'package:nestprep/features/documents/model/household_document.dart';
import 'package:nestprep/features/documents/state/document_library_controller.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_documents.dart';
import '../../../support/fake_link_opener.dart';
import '../../../support/fake_vault.dart';
import '../../../support/household_fixtures.dart';

DocumentFolder folder(String id, String name) =>
    DocumentFolder(id: id, name: name, createdBy: Fixtures.samMemberId);

HouseholdDocument document(
  String id, {
  String folderId = 'f-school',
  String uploadedBy = Fixtures.samMemberId,
  String contentType = 'application/pdf',
}) => HouseholdDocument(
  id: id,
  folderId: folderId,
  name: id,
  contentType: contentType,
  sizeBytes: 1024,
  uploadedBy: uploadedBy,
);

/// `AppFailure` has no value equality, so a held refusal is checked by the
/// problem it names rather than by identity.
void expectProblem(Object? failure, DocumentProblem problem) {
  expect(failure, isA<DocumentFailure>());
  expect((failure! as DocumentFailure).problem, problem);
}

void main() {
  late FakeDocumentRepository repository;
  late FakeDocumentStore store;
  late FakeDocumentDirectory directory;
  late FakeDocumentPicker picker;
  late FakeLinkOpener opener;

  DocumentLibraryController build({bool isAdmin = true}) =>
      DocumentLibraryController(
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

  setUp(() {
    repository = FakeDocumentRepository();
    store = FakeDocumentStore();
    directory = FakeDocumentDirectory();
    picker = FakeDocumentPicker();
    opener = FakeLinkOpener();
  });

  tearDown(() => repository.close());

  group('the library', () {
    test('holds one loading state until both reads have answered', () async {
      final controller = build();
      addTearDown(controller.dispose);

      expect(controller.library, isA<AsyncLoading<Object>>());
      repository.emitFolders([folder('f-school', 'School')]);
      await Future<void>.delayed(Duration.zero);
      // One of two: the screen must not flash a half-built library.
      expect(controller.library, isA<AsyncLoading<Object>>());

      repository.emitDocuments([]);
      await Future<void>.delayed(Duration.zero);
      expect(controller.library, isA<AsyncData<Object>>());
    });

    test('files each document under the folder it names', () async {
      final controller = build();
      addTearDown(controller.dispose);
      repository.emitFolders([
        folder('f-school', 'School'),
        folder('f-house', 'House'),
      ]);
      repository.emitDocuments([
        document('d1'),
        document('d2'),
        document('d3', folderId: 'f-house'),
      ]);
      await Future<void>.delayed(Duration.zero);

      final library = (controller.library as AsyncData<DocumentLibrary>).value;
      expect(library.countIn('f-school'), 2);
      expect(library.countIn('f-house'), 1);
      expect(library.countIn('f-gone'), 0);
    });

    test('a refused read becomes a failure, not an exception', () async {
      final controller = build();
      addTearDown(controller.dispose);
      repository.failFoldersWith(const PermissionDeniedFailure());
      await Future<void>.delayed(Duration.zero);

      expect(controller.library, isA<AsyncFailure<Object>>());
    });
  });

  group('the household claim Storage rules read', () {
    test('is synced before anything touches Storage', () async {
      final controller = build();
      addTearDown(controller.dispose);
      await Future<void>.delayed(Duration.zero);

      expect(directory.syncCount, 1);
    });

    test('and a refusal to sync is shown rather than swallowed', () async {
      // Without the claim every document in the household is unreadable, and
      // the person would meet a permission error with no explanation.
      directory.failSyncWith = const UnavailableFailure();
      final controller = build();
      addTearDown(controller.dispose);
      await Future<void>.delayed(Duration.zero);

      expect(controller.actionFailure, isA<UnavailableFailure>());
    });
  });

  group('adding a document', () {
    test('says nothing when somebody backs out of the picker', () async {
      final controller = build();
      addTearDown(controller.dispose);
      picker.next = null;

      await controller.addDocument('f-school');

      expect(store.uploads, isEmpty);
      expect(controller.actionFailure, isNull);
    });

    test('refuses a file past the cap before it is sent', () async {
      final controller = build();
      addTearDown(controller.dispose);
      picker.next = pickedDocument(sizeBytes: DocumentLimits.maxSizeBytes + 1);

      await controller.addDocument('f-school');

      expect(store.uploads, isEmpty, reason: 'nobody should wait for that');
      expectProblem(controller.actionFailure, DocumentProblem.fileTooLarge);
    });

    test('refuses a type the household does not keep', () async {
      final controller = build();
      addTearDown(controller.dispose);
      picker.next = pickedDocument(contentType: 'application/zip');

      await controller.addDocument('f-school');

      expect(store.uploads, isEmpty);
      expectProblem(controller.actionFailure, DocumentProblem.unsupportedType);
    });

    test('reports progress, then writes the row', () async {
      final controller = build();
      addTearDown(controller.dispose);
      final upload = FakeDocumentUpload();
      store.nextUpload = upload;
      picker.next = pickedDocument(name: 'Lease.pdf');

      final adding = controller.addDocument('f-school');
      await Future<void>.delayed(Duration.zero);
      expect(controller.upload?.fileName, 'Lease.pdf');

      upload.emit(0.5);
      await Future<void>.delayed(Duration.zero);
      expect(controller.upload?.fraction, 0.5);

      await upload.finish();
      await adding;

      expect(controller.upload, isNull);
      expect(repository.added.single.folderId, 'f-school');
      expect(repository.added.single.name, 'Lease.pdf');
      // The row is written under the id the bytes went to, which is what makes
      // one findable from the other (documents ADR-0001).
      expect(
        repository.added.single.documentId,
        store.uploads.single.documentId,
      );
    });

    test('stamps the bytes with the account, not the profile', () async {
      // Storage rules know uids; Firestore rules know member profiles. Both
      // are the same person, and each layer is given the one it can check.
      final controller = build();
      addTearDown(controller.dispose);
      final upload = FakeDocumentUpload();
      store.nextUpload = upload;
      picker.next = pickedDocument();

      final adding = controller.addDocument('f-school');
      await Future<void>.delayed(Duration.zero);
      await upload.finish();
      await adding;

      expect(store.uploads.single.uploaderUid, Fixtures.samUid);
      expect(
        repository.added.single.documentId,
        store.uploads.single.documentId,
      );
    });

    test('a stopped upload says so, and can be tried again', () async {
      final controller = build();
      addTearDown(controller.dispose);
      final first = FakeDocumentUpload();
      store.nextUpload = first;
      picker.next = pickedDocument();

      final adding = controller.addDocument('f-school');
      await Future<void>.delayed(Duration.zero);
      await controller.cancelUpload();
      await adding;

      expect(first.isCancelled, isTrue);
      expectProblem(controller.actionFailure, DocumentProblem.uploadCancelled);
      expect(controller.canRetryUpload, isTrue);
      expect(repository.added, isEmpty, reason: 'no bytes, no row');

      final second = FakeDocumentUpload();
      store.nextUpload = second;
      final retry = controller.retryUpload();
      await Future<void>.delayed(Duration.zero);
      await second.finish();
      await retry;

      expect(repository.added, hasLength(1));
      expect(
        picker.pickCount,
        1,
        reason: 'retrying should not ask for the file again',
      );
    });

    test('giving up on a failed upload clears it from the screen', () async {
      final controller = build();
      addTearDown(controller.dispose);
      final upload = FakeDocumentUpload();
      store.nextUpload = upload;
      picker.next = pickedDocument();

      final adding = controller.addDocument('f-school');
      await Future<void>.delayed(Duration.zero);
      await upload.fail(const UnavailableFailure());
      await adding;

      expect(controller.canRetryUpload, isTrue);
      controller.forgetUpload();
      expect(controller.canRetryUpload, isFalse);
      expect(controller.actionFailure, isNull);
    });

    test('deletes the bytes again when the row cannot be written', () async {
      // This is the orphan: bytes in the bucket that no row points at, which
      // nobody can see and nobody stops paying for (`BE-07`).
      final controller = build();
      addTearDown(controller.dispose);
      final upload = FakeDocumentUpload();
      store.nextUpload = upload;
      picker.next = pickedDocument();
      repository.failAddDocumentWith = const PermissionDeniedFailure();

      final adding = controller.addDocument('f-school');
      await Future<void>.delayed(Duration.zero);
      await upload.finish();
      await adding;

      expect(controller.actionFailure, isA<PermissionDeniedFailure>());
      expect(store.removedBytes, [store.uploads.single.documentId]);
    });
  });

  group('scanning into a folder (documents ADR-0004)', () {
    test(
      'the sides become one PDF, added under the name somebody gave it',
      () async {
        final composer = FakeScanComposer();
        final controller = DocumentLibraryController(
          documentRepository: repository,
          documentStore: store,
          documentDirectory: directory,
          documentPicker: picker,
          documentOpener: opener,
          scanIntake: fakeScanIntake(composer: composer),
          householdId: Fixtures.householdId,
          memberId: Fixtures.samMemberId,
          viewerUid: Fixtures.samUid,
          isAdmin: true,
        );
        addTearDown(controller.dispose);

        final sides = (await controller.scanSides())!;
        final adding = controller.addScan(
          'f-home',
          pages: sides,
          name: 'Car licence',
        );
        await pumpEventQueue();
        await store.nextUpload!.finish();
        await adding;

        expect(composer.composed, [2]);
        expect(repository.added.single.name, 'Car licence');
        expect(repository.added.single.folderId, 'f-home');
        expect(controller.isPreparing, isFalse);
      },
    );

    test('a scanner that cannot run is said on screen', () async {
      final scanner = FakeDocumentScanner()
        ..failWith = const DocumentFailure(DocumentProblem.scanFailed);
      final controller = DocumentLibraryController(
        documentRepository: repository,
        documentStore: store,
        documentDirectory: directory,
        documentPicker: picker,
        documentOpener: opener,
        scanIntake: fakeScanIntake(scanner: scanner),
        householdId: Fixtures.householdId,
        memberId: Fixtures.samMemberId,
        viewerUid: Fixtures.samUid,
        isAdmin: true,
      );
      addTearDown(controller.dispose);

      expect(await controller.scanSides(), isNull);
      expect(controller.actionFailure, isA<DocumentFailure>());
    });
  });

  group('deleting a document', () {
    test('takes the bytes before the row', () async {
      final controller = build();
      addTearDown(controller.dispose);

      await controller.deleteDocument(document('d1'));

      expect(store.removedBytes, ['d1']);
      expect(repository.removed, ['d1']);
    });

    test('leaves the row alone when the bytes refuse to go', () async {
      // The row stays visible, which is the point: somebody can try again.
      final controller = build();
      addTearDown(controller.dispose);
      store.failRemoveWith = const PermissionDeniedFailure();

      await controller.deleteDocument(document('d1'));

      expect(repository.removed, isEmpty);
      expect(controller.actionFailure, isA<PermissionDeniedFailure>());
    });

    test('finishes a delete that was interrupted after the bytes', () async {
      final controller = build();
      addTearDown(controller.dispose);
      store.failRemoveWith = const NotFoundFailure();

      await controller.deleteDocument(document('d1'));

      expect(repository.removed, ['d1']);
      expect(controller.actionFailure, isNull);
    });
  });

  group('opening a document', () {
    test('reads the bytes through the store for an image', () async {
      final controller = build();
      addTearDown(controller.dispose);

      final bytes = await controller.readDocument(
        document('d1', contentType: 'image/png'),
      );

      expect(bytes, isNotEmpty);
    });

    test('hands anything else to the device', () async {
      final controller = build();
      addTearDown(controller.dispose);

      await controller.openOutside(document('d1'));

      expect(opener.opened, [store.link]);
      expect(controller.actionFailure, isNull);
    });

    test('says so when nothing on the device would take it', () async {
      final controller = build();
      addTearDown(controller.dispose);
      opener.opens = false;

      await controller.openOutside(document('d1'));

      expectProblem(controller.actionFailure, DocumentProblem.cannotOpen);
    });
  });

  group('folders', () {
    test(
      'an admin makes one, trimmed, and an empty name is not a write',
      () async {
        final controller = build();
        addTearDown(controller.dispose);

        await controller.createFolder('  School  ');
        await controller.createFolder('   ');

        expect(repository.createdFolders, ['School']);
      },
    );

    test('renaming goes through the repository', () async {
      final controller = build();
      addTearDown(controller.dispose);

      await controller.renameFolder(folder('f-school', 'School'), 'Kids');

      expect(repository.renamedFolders.single.name, 'Kids');
    });

    test('deleting goes through the callable, never a client write', () async {
      // Only it can see whether the folder is still holding anything.
      final controller = build();
      addTearDown(controller.dispose);

      await controller.deleteFolder(folder('f-school', 'School'));

      expect(directory.deletedFolders, ['f-school']);
    });

    test('a folder that still holds documents comes back refused', () async {
      final controller = build();
      addTearDown(controller.dispose);
      directory.failDeleteWith = const DocumentFailure(
        DocumentProblem.folderNotEmpty,
      );

      await controller.deleteFolder(folder('f-school', 'School'));

      expectProblem(controller.actionFailure, DocumentProblem.folderNotEmpty);
    });
  });
}
