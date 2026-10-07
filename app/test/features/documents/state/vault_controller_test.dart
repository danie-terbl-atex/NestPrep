import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/documents/model/vault_grant.dart';
import 'package:nestprep/features/documents/model/vault_upload_details.dart';
import 'package:nestprep/features/documents/state/vault_controller.dart';
import 'package:nestprep/features/documents/state/vault_lock_controller.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

import '../../../support/fake_documents.dart';
import '../../../support/fake_vault.dart';
import '../../../support/household_fixtures.dart';

/// The vaults while they are open (documents ADR-0002, ADR-0003): which vaults
/// a person sees, that locking drops everything, that opening a document is
/// logged before a byte is read, and that adding one keeps bytes and rows in
/// the order that leaves nothing orphaned.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeVaultRepository repository;
  late FakeVaultStore store;
  late FakeDocumentDirectory directory;
  late FakeDocumentPicker picker;
  late FakePdfPageRenderer renderer;
  late FakeDocumentScanner scanner;
  late FakeScanComposer composer;
  late VaultLockController lock;
  late VaultController controller;

  VaultController build({
    String memberId = Fixtures.samMemberId,
    String viewerUid = Fixtures.samUid,
    bool isFamily = true,
  }) => VaultController(
    vaultRepository: repository,
    vaultStore: store,
    documentDirectory: directory,
    documentPicker: picker,
    pdfPageRenderer: renderer,
    scanIntake: fakeScanIntake(scanner: scanner, composer: composer),
    lock: lock,
    householdId: Fixtures.householdId,
    members: [Fixtures.sam, Fixtures.thandi, Fixtures.kid],
    memberId: memberId,
    viewerUid: viewerUid,
    isFamily: isFamily,
  );

  setUp(() {
    repository = FakeVaultRepository();
    store = FakeVaultStore();
    directory = FakeDocumentDirectory();
    picker = FakeDocumentPicker();
    renderer = FakePdfPageRenderer();
    scanner = FakeDocumentScanner();
    composer = FakeScanComposer();
    lock = VaultLockController(deviceLock: FakeDeviceLock(), reason: 'test');
    controller = build();
  });

  tearDown(() async {
    controller.dispose();
    lock.dispose();
    await repository.close();
  });

  /// Everything an admin listens to, answered.
  Future<void> answerAdmin() async {
    for (final member in [Fixtures.sam, Fixtures.thandi, Fixtures.kid]) {
      repository.emitVault(member.id, []);
      repository.emitGrants(member.id, []);
    }
    await pumpEventQueue();
  }

  group('while locked', () {
    test('listens to nothing and shows nothing', () async {
      await pumpEventQueue();
      expect(repository.watchedVaults, isEmpty);
      expect(controller.shelf, isA<AsyncLoading<Object?>>());
    });
  });

  group('an admin', () {
    test(
      'sees every vault, a child\'s included, and manages them all',
      () async {
        await lock.unlock();
        await answerAdmin();

        expect(repository.watchedVaults, {'m-sam', 'm-thandi', 'm-kid'});
        final shelf = controller.loadedShelf!;
        expect(
          [for (final owner in shelf.owners) owner.id],
          ['m-sam', 'm-thandi', 'm-kid'],
        );
        expect(shelf.canManage('m-kid'), isTrue);
      },
    );

    test('does not show a half-loaded shelf', () async {
      await lock.unlock();
      repository.emitVault('m-sam', [vaultDocument('p1')]);
      await pumpEventQueue();
      expect(controller.shelf, isA<AsyncLoading<Object?>>());
    });
  });

  group('a helper', () {
    setUp(() {
      controller.dispose();
      controller = build(
        memberId: Fixtures.thandiMemberId,
        viewerUid: Fixtures.thandiUid,
        isFamily: false,
      );
    });

    test('sees only her own vault until somebody shares theirs', () async {
      await lock.unlock();
      repository.emitVault('m-thandi', []);
      repository.emitGrants('m-thandi', []);
      repository.emitGrantTo('m-sam', isGranted: false);
      repository.emitGrantTo('m-kid', isGranted: false);
      await pumpEventQueue();

      expect(repository.watchedVaults, {'m-thandi'});
      expect(
        [for (final owner in controller.loadedShelf!.owners) owner.id],
        ['m-thandi'],
      );
    });

    test(
      'gains a vault when it is shared, read-only, and loses it on revoke',
      () async {
        await lock.unlock();
        repository.emitVault('m-thandi', []);
        repository.emitGrants('m-thandi', []);
        repository.emitGrantTo('m-sam', isGranted: false);
        repository.emitGrantTo('m-kid', isGranted: true);
        await pumpEventQueue();
        repository.emitVault('m-kid', [vaultDocument('passport')]);
        await pumpEventQueue();

        var shelf = controller.loadedShelf!;
        expect(shelf.canOpen('m-kid'), isTrue);
        expect(shelf.canManage('m-kid'), isFalse);
        expect(shelf.documentsOf('m-kid').single.id, 'passport');

        repository.emitGrantTo('m-kid', isGranted: false);
        await pumpEventQueue();
        shelf = controller.loadedShelf!;
        expect(shelf.canOpen('m-kid'), isFalse);
        expect(repository.watchedVaults, {'m-thandi'});
      },
    );
  });

  test('locking closes every listener and drops what they brought', () async {
    await lock.unlock();
    await answerAdmin();
    expect(controller.loadedShelf, isNotNull);

    lock.lock();
    await pumpEventQueue();

    expect(controller.loadedShelf, isNull);
    expect(repository.watchedVaults, isEmpty);
  });

  group('opening a document', () {
    test('logs the open on the server before a byte is read', () async {
      await lock.unlock();
      await answerAdmin();
      final passport = vaultDocument(
        'passport',
      ).copyWith(ownerMemberId: 'm-kid');

      final pages = await controller.openPages(passport);

      expect(directory.opened.single, (
        ownerMemberId: 'm-kid',
        documentId: 'passport',
      ));
      expect(store.reads, ['passport']);
      expect(renderer.renders, 1, reason: 'a PDF is drawn by the app itself');
      expect(pages, renderer.pages);
    });

    test('a refused open reads nothing at all', () async {
      directory.failOpenWith = const DocumentFailure(
        DocumentProblem.vaultNotShared,
      );
      final passport = vaultDocument(
        'passport',
      ).copyWith(ownerMemberId: 'm-kid');

      await expectLater(
        controller.openPages(passport),
        throwsA(isA<DocumentFailure>()),
      );
      expect(store.reads, isEmpty);
    });

    test('a photo is shown as it is, without the PDF renderer', () async {
      final card = vaultDocument(
        'card',
        contentType: 'image/jpeg',
      ).copyWith(ownerMemberId: 'm-kid');
      final pages = await controller.openPages(card);
      expect(pages.single, store.bytes);
      expect(renderer.renders, 0);
    });
  });

  group('adding', () {
    const details = VaultUploadDetails(
      ownerMemberId: 'm-kid',
      name: 'Passport',
      tags: ['ID'],
    );

    test(
      'a scan becomes one PDF, its bytes stored under the owner, then its row',
      () async {
        await lock.unlock();
        final sides = (await controller.scan())!;
        expect(scanner.askedForPages, 2, reason: 'front and back');

        final adding = controller.addScan(sides, details);
        await pumpEventQueue();
        store.nextUpload!.emit(1);
        await store.nextUpload!.finish();
        await adding;

        expect(composer.composed, [2]);
        expect(store.uploads.single.owner, 'm-kid');
        expect(store.uploads.single.uploaderUid, Fixtures.samUid);
        final row = repository.added.single;
        expect(row.ownerMemberId, 'm-kid');
        expect(row.contentType, 'application/pdf');
        expect(row.tags, ['ID']);
        expect(row.uploadedBy, Fixtures.samMemberId);
      },
    );

    test('backing out of the scanner adds nothing and says nothing', () async {
      scanner.next = null;
      expect(await controller.scan(), isNull);
      expect(controller.actionFailure, isNull);
    });

    test('a scanner that cannot run says so', () async {
      scanner.failWith = const DocumentFailure(DocumentProblem.cameraRefused);
      expect(await controller.scan(), isNull);
      expect(controller.actionFailure, isA<DocumentFailure>());
    });

    test(
      'a scan that cannot be composed is refused before any upload',
      () async {
        composer.failWith = const DocumentFailure(DocumentProblem.cannotRender);
        await controller.addScan([Uint8List(1)], details);
        expect(store.uploads, isEmpty);
        expect(controller.actionFailure, isA<DocumentFailure>());
        expect(controller.isPreparing, isFalse);
      },
    );

    test(
      'a file the rules would refuse is refused before the upload',
      () async {
        picker.next = pickedDocument(contentType: 'application/zip');
        expect(await controller.pickFile(), isNull);
        expect(controller.actionFailure, isA<DocumentFailure>());
      },
    );

    test('bytes whose row cannot be written are taken away again', () async {
      repository.failWritesWith = const PermissionDeniedFailure();
      final adding = controller.addFile(pickedDocument(), details);
      await pumpEventQueue();
      await store.nextUpload!.finish();
      await adding;

      expect(store.removedBytes, ['vault-doc-1']);
      expect(controller.actionFailure, isA<PermissionDeniedFailure>());
      // The file is kept, so trying again is one tap rather than a rescan.
      expect(controller.canRetryUpload, isTrue);
    });
  });

  group('changing', () {
    test('edits a document\'s name, tags and expiry', () async {
      final passport = vaultDocument(
        'passport',
      ).copyWith(ownerMemberId: 'm-kid');
      await controller.editDocument(
        passport,
        name: ' Emma passport ',
        tags: const ['ID'],
        expiresOn: CalendarDate(2031, 4, 30),
      );
      expect(repository.edited.single.name, 'Emma passport');
      expect(repository.edited.single.expiresOn, CalendarDate(2031, 4, 30));
    });

    test('deletes the bytes first, then the row', () async {
      final passport = vaultDocument(
        'passport',
      ).copyWith(ownerMemberId: 'm-kid');
      await controller.deleteDocument(passport);
      expect(store.removedBytes, ['passport']);
      expect(repository.removed, ['passport']);
    });

    test(
      'shares a vault with somebody who has joined, by their account',
      () async {
        await controller.share('m-kid', Fixtures.thandi);
        expect(repository.granted.single, (
          owner: 'm-kid',
          granteeUid: Fixtures.thandiUid,
          memberId: Fixtures.thandiMemberId,
        ));
        await controller.unshare('m-kid', Fixtures.thandiUid);
        expect(repository.revoked.single.granteeUid, Fixtures.thandiUid);
      },
    );

    test('cannot share with a profile nobody has claimed', () async {
      await controller.share('m-sam', Fixtures.kid);
      expect(repository.granted, isEmpty);
    });

    test('a refused share shows copy', () async {
      repository.failWritesWith = const PermissionDeniedFailure();
      await controller.share('m-kid', Fixtures.thandi);
      expect(controller.actionFailure, isA<PermissionDeniedFailure>());
    });
  });

  test(
    'a vault that cannot be read shows the failure, not an empty vault',
    () async {
      await lock.unlock();
      repository.failVault('m-kid', const PermissionDeniedFailure());
      await pumpEventQueue();
      expect(controller.shelf, isA<AsyncFailure<Object?>>());
    },
  );

  test('grants arrive on the shelf for the vaults a person manages', () async {
    await lock.unlock();
    await answerAdmin();
    repository.emitGrants('m-kid', [
      const VaultGrant(
        id: Fixtures.thandiUid,
        memberId: Fixtures.thandiMemberId,
        grantedBy: 'm-sam',
      ),
    ]);
    await pumpEventQueue();
    expect(
      controller.loadedShelf!.grantsOf('m-kid').single.granteeUid,
      Fixtures.thandiUid,
    );
  });
}
