import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/documents/data/offline_access_check.dart';
import 'package:nestprep/features/documents/data/offline_copy_store.dart';
import 'package:nestprep/features/documents/model/household_document.dart';
import 'package:nestprep/features/documents/model/offline_copy.dart';
import 'package:nestprep/features/documents/model/vault_lock_state.dart';
import 'package:nestprep/features/documents/state/offline_copies_controller.dart';
import 'package:nestprep/features/documents/state/offline_copy_source.dart';
import 'package:nestprep/features/documents/state/vault_lock_controller.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/copy/vault_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_document_tools.dart';
import '../../../support/fake_documents.dart';
import '../../../support/fake_vault.dart';
import '../../../support/household_fixtures.dart';

/// The phone's offline copies for one household (documents ADR-0007): behind
/// the vaults' lock, checked with the server each time they are opened,
/// taken through the same logged open as any vault read, and never more than
/// twenty.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InMemoryOfflineCopyStore store;
  late FakeOfflineAccessCheck check;
  late FakeDocumentStore documentStore;
  late FakeVaultStore vaultStore;
  late FakeDocumentDirectory directory;
  late FakeDeviceLock deviceLock;
  late VaultLockController lock;
  late OfflineCopiesController controller;

  const uid = Fixtures.samUid;

  setUp(() {
    store = InMemoryOfflineCopyStore();
    check = FakeOfflineAccessCheck();
    documentStore = FakeDocumentStore();
    vaultStore = FakeVaultStore();
    directory = FakeDocumentDirectory();
    deviceLock = FakeDeviceLock();
    lock = VaultLockController(
      deviceLock: deviceLock,
      reason: VaultCopy.unlockReason,
    );
    controller = OfflineCopiesController(
      store: store,
      accessCheck: check,
      source: OfflineCopySource(
        documentStore: documentStore,
        vaultStore: vaultStore,
        documentDirectory: directory,
        householdId: Fixtures.householdId,
      ),
      pdfPageRenderer: FakePdfPageRenderer(),
      lock: lock,
      householdId: Fixtures.householdId,
      uid: uid,
      now: () => DateTime.utc(2026, 9, 29, 9),
    );
  });

  tearDown(() {
    controller.dispose();
    lock.dispose();
  });

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  Future<void> unlock() async {
    await lock.unlock();
    for (var turn = 0; turn < 5; turn++) {
      await settle();
    }
  }

  List<String> shownIds() => switch (controller.shelf) {
    AsyncData(:final value) => [for (final c in value.copies) c.documentId],
    _ => const [],
  };

  const houseDocument = HouseholdDocument(
    id: 'policy',
    folderId: 'f1',
    name: 'Car insurance',
    contentType: 'image/png',
    sizeBytes: 3,
    uploadedBy: Fixtures.samMemberId,
  );

  group('behind the lock', () {
    test('reads nothing while locked — not even a name', () async {
      await store.save(uid, anOfflineCopy('a'), onePixelPng);
      await settle();

      expect(controller.shelf, isA<AsyncLoading<Object?>>());
      expect(controller.holds(ownerMemberId: null, documentId: 'a'), isFalse);
      expect(check.checked, isEmpty);
    });

    test('shows this household\'s copies once unlocked, and drops them when '
        'it locks again', () async {
      await store.save(uid, anOfflineCopy('a'), onePixelPng);
      await store.save(uid, anOfflineCopy('z', householdId: 'h2'), onePixelPng);

      await unlock();
      expect(shownIds(), ['a']);
      expect(controller.holds(ownerMemberId: null, documentId: 'a'), isTrue);

      lock.lock();
      expect(controller.shelf, isA<AsyncLoading<Object?>>());
      expect(controller.holds(ownerMemberId: null, documentId: 'a'), isFalse);
    });

    test(
      'a read the phone refuses is shown as a failure, with a retry',
      () async {
        final failing = _FailingStore();
        final other = OfflineCopiesController(
          store: failing,
          accessCheck: check,
          source: OfflineCopySource(
            documentStore: documentStore,
            vaultStore: vaultStore,
            documentDirectory: directory,
            householdId: Fixtures.householdId,
          ),
          pdfPageRenderer: FakePdfPageRenderer(),
          lock: lock,
          householdId: Fixtures.householdId,
          uid: uid,
        );
        addTearDown(other.dispose);
        await unlock();
        expect(other.shelf, isA<AsyncFailure<Object?>>());
      },
    );
  });

  group('checked with the server each time', () {
    test('a copy the person can no longer open is deleted', () async {
      await store.save(uid, anOfflineCopy('kept'), onePixelPng);
      await store.save(
        uid,
        anOfflineCopy('revoked', ownerMemberId: 'm-kid'),
        onePixelPng,
      );
      check.answers['revoked'] = OfflineAccess.lost;

      await unlock();

      expect(shownIds(), ['kept']);
      expect(await store.list(uid), hasLength(1));
      expect(controller.hasChecked, isTrue);
    });

    test('no answer keeps the copy — that is what offline is for', () async {
      await store.save(uid, anOfflineCopy('card'), onePixelPng);
      check.answers['card'] = OfflineAccess.unknown;

      await unlock();

      expect(shownIds(), ['card']);
    });
  });

  group('taking a copy', () {
    test('of a vault document goes through the logged open first', () async {
      await unlock();
      final document = vaultDocument(
        'passport',
      ).copyWith(ownerMemberId: Fixtures.kidMemberId);

      await controller.saveVaultDocument(document);

      expect(directory.opened, [
        (ownerMemberId: Fixtures.kidMemberId, documentId: 'passport'),
      ]);
      expect(
        controller.holds(
          ownerMemberId: Fixtures.kidMemberId,
          documentId: 'passport',
        ),
        isTrue,
      );
    });

    test('of a household document reads its bytes directly', () async {
      await unlock();

      await controller.saveHouseholdDocument(houseDocument);

      final kept = await store.list(uid);
      expect(kept.single.name, 'Car insurance');
      expect(kept.single.savedAt, DateTime.utc(2026, 9, 29, 9));
      expect(directory.opened, isEmpty);
    });

    test('asks for the lock first when it is shut, and keeps nothing when '
        'the phone says no', () async {
      deviceLock.outcome = UnlockOutcome.cancelled;

      await controller.saveHouseholdDocument(houseDocument);

      expect(deviceLock.asked, 1);
      expect(await store.list(uid), isEmpty);
    });

    test('stops at twenty on this phone, across every household', () async {
      for (var index = 0; index < 19; index++) {
        await store.save(uid, anOfflineCopy('d$index'), onePixelPng);
      }
      await store.save(
        uid,
        anOfflineCopy('far', householdId: 'h2'),
        onePixelPng,
      );
      await unlock();

      await controller.saveHouseholdDocument(houseDocument);

      expect(
        controller.actionFailure,
        isA<DocumentFailure>().having(
          (failure) => failure.problem,
          'problem',
          DocumentProblem.offlineLimitReached,
        ),
      );
      expect(await store.list(uid), hasLength(20));
    });

    test('a refused read is kept for the screen, not thrown at it', () async {
      await unlock();
      directory.failOpenWith = const DocumentFailure(
        DocumentProblem.vaultNotShared,
      );

      await controller.saveVaultDocument(
        vaultDocument('x').copyWith(ownerMemberId: Fixtures.kidMemberId),
      );

      expect(controller.actionFailure, isA<DocumentFailure>());
      expect(controller.isSaving('x'), isFalse);
    });
  });

  group('opening and removing', () {
    test('opens a picture from the phone, with no connection needed', () async {
      await store.save(uid, anOfflineCopy('card'), onePixelPng);
      await unlock();

      final pages = await controller.openPages(anOfflineCopy('card'));

      expect(pages.single, onePixelPng);
    });

    test('a copy that will not decrypt is removed and reported', () async {
      await store.save(uid, anOfflineCopy('card'), onePixelPng);
      await unlock();
      store.failReadWith = const DocumentFailure(
        DocumentProblem.offlineCopyUnreadable,
      );

      await expectLater(
        controller.openPages(anOfflineCopy('card')),
        throwsA(isA<DocumentFailure>()),
      );
      expect(shownIds(), isEmpty);
    });

    test('removes one by where it lives, or all of them', () async {
      await store.save(uid, anOfflineCopy('a'), onePixelPng);
      await store.save(uid, anOfflineCopy('b'), onePixelPng);
      await unlock();

      await controller.removeDocument(ownerMemberId: null, documentId: 'a');
      expect(shownIds(), ['b']);

      await controller.removeAll();
      expect(shownIds(), isEmpty);
    });
  });
}

final class _FailingStore implements OfflineCopyStore {
  static const _refusal = DocumentFailure(
    DocumentProblem.offlineStorageUnavailable,
  );

  @override
  Future<List<OfflineCopy>> list(String uid) async => throw _refusal;

  @override
  Future<void> save(String uid, OfflineCopy copy, Uint8List bytes) async =>
      throw _refusal;

  @override
  Future<Uint8List> read(String uid, OfflineCopy copy) async => throw _refusal;

  @override
  Future<void> remove(String uid, Iterable<OfflineCopy> copies) async =>
      throw _refusal;

  @override
  Future<void> keepOnly(String? uid) async => throw _refusal;
}
