import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/nanny_hub/state/photo_library.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_documents.dart';
import '../../../support/fake_nanny_access.dart';
import '../../../support/fake_nanny_hub.dart';

void main() {
  late FakePhotoStore store;
  late FakeDocumentDirectory directory;
  late PhotoLibrary library;
  final compressed = <Uint8List>[];

  setUp(() {
    store = FakePhotoStore();
    directory = FakeDocumentDirectory();
    compressed.clear();
    library = PhotoLibrary(
      photoStore: store,
      documentDirectory: directory,
      householdId: 'h1',
      uploaderUid: 'uid-nomsa',
      compress: (bytes) async {
        compressed.add(bytes);
        return Uint8List.fromList([...bytes, 0]);
      },
    );
  });

  tearDown(() => library.dispose());

  test('fetches a photo once, however often it is asked for', () async {
    store.objects['p1'] = Uint8List.fromList([1, 2]);
    library.ensure(['p1', null, 'p1']);
    library.ensure(['p1']);
    await pumpEventQueue();
    expect(store.reads, ['p1']);
    expect(library.stateOf('p1'), isA<AsyncData<Uint8List>>());
  });

  test(
    'puts the grant on the token once, before the first Storage call',
    () async {
      store.objects['p1'] = Uint8List(1);
      store.objects['p2'] = Uint8List(1);
      library.ensure(['p1', 'p2']);
      await pumpEventQueue();
      expect(directory.syncCount, 1);
    },
  );

  test('a claim that would not refresh fails the photo, and is asked again '
      'on retry', () async {
    directory.failSyncWith = const UnavailableFailure();
    library.ensure(['p1']);
    await pumpEventQueue();
    expect(library.stateOf('p1'), isA<AsyncFailure<Uint8List>>());
    expect(store.reads, isEmpty);

    directory.failSyncWith = null;
    store.objects['p1'] = Uint8List(1);
    library.retry('p1');
    await pumpEventQueue();
    expect(directory.syncCount, 2);
    expect(library.stateOf('p1'), isA<AsyncData<Uint8List>>());
  });

  test(
    'a photo that will not read says so, rather than loading for ever',
    () async {
      store.failReadsWith = const PermissionDeniedFailure();
      library.ensure(['p1']);
      await pumpEventQueue();
      expect(
        library.stateOf('p1'),
        isA<AsyncFailure<Uint8List>>().having(
          (state) => state.failure,
          'failure',
          isA<PermissionDeniedFailure>(),
        ),
      );
    },
  );

  test('stores a picked photo compressed, stamped with the uploader, and '
      'holds it at once', () async {
    final photoId = await library.store(Uint8List.fromList([9]));
    expect(compressed.single, [9]);
    expect(store.objects[photoId], [9, 0]);
    expect(library.stateOf(photoId), isA<AsyncData<Uint8List>>());
  });

  test('a store that fails throws the reason for the banner', () async {
    store.failUploadsWith = const PermissionDeniedFailure();
    await expectLater(
      library.store(Uint8List(1)),
      throwsA(isA<PermissionDeniedFailure>()),
    );
  });

  test('discards a photo nothing points at, and a failure there is only a '
      'log line', () async {
    final photoId = await library.store(Uint8List(1));
    await library.discard(photoId);
    expect(store.removed, [photoId]);
    directory.failSyncWith = const UnavailableFailure();
    final fresh = PhotoLibrary(
      photoStore: store,
      documentDirectory: directory,
      householdId: 'h1',
      uploaderUid: 'uid',
    );
    addTearDown(fresh.dispose);
    await fresh.discard('p-orphan');
    expect(store.removed, [photoId]);
  });

  test('holds a bounded number of photos, letting the oldest go', () async {
    for (var index = 0; index <= PhotoLibrary.heldLimit; index++) {
      store.objects['p$index'] = Uint8List(1);
    }
    library.ensure([
      for (var index = 0; index <= PhotoLibrary.heldLimit; index++) 'p$index',
    ]);
    await pumpEventQueue();
    expect(library.stateOf('p0'), isA<AsyncLoading<Uint8List>>());
    expect(
      library.stateOf('p${PhotoLibrary.heldLimit}'),
      isA<AsyncData<Uint8List>>(),
    );
  });

  group('saved for offline (nanny-hub ADR-0007)', () {
    late FakeOfflineShelf shelf;
    late PhotoLibrary offline;

    setUp(() {
      shelf = FakeOfflineShelf();
      offline = PhotoLibrary(
        photoStore: store,
        documentDirectory: directory,
        householdId: 'h1',
        uploaderUid: 'uid-nomsa',
        shelf: shelf,
        compress: (bytes) async => bytes,
      );
    });

    tearDown(() => offline.dispose());

    test('a photo on the shelf shows without a signal — Storage is never '
        'asked', () async {
      shelf.photos['h1/p1'] = Uint8List.fromList([4, 2]);
      offline.ensure(['p1']);
      await pumpEventQueue();
      expect(store.reads, isEmpty);
      expect(directory.syncCount, 0);
      final state = offline.stateOf('p1') as AsyncData<Uint8List>;
      expect(state.value, [4, 2]);
    });

    test('a photo not on the shelf comes from Storage as before', () async {
      store.objects['p1'] = Uint8List.fromList([1]);
      offline.ensure(['p1']);
      await pumpEventQueue();
      expect(store.reads, ['p1']);
      expect(offline.stateOf('p1'), isA<AsyncData<Uint8List>>());
    });

    test('a shelf that will not read is no worse than no shelf', () async {
      shelf.failWith = const NannyHubFailure(NannyHubProblem.cannotSaveOffline);
      store.objects['p1'] = Uint8List.fromList([1]);
      offline.ensure(['p1']);
      await pumpEventQueue();
      expect(offline.stateOf('p1'), isA<AsyncData<Uint8List>>());
    });
  });
}
