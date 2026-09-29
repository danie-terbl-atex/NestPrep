import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/nanny_hub/model/offline_status.dart';
import 'package:nestprep/features/nanny_hub/state/offline_keeper.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_documents.dart';
import '../../../support/fake_nanny_access.dart';
import '../../../support/fake_nanny_hub.dart';

/// Works offline (nanny-hub ADR-0007): the keeper reads the hub fresh from the
/// server so Firestore's cache holds it, keeps its photos on the phone's own
/// shelf, and says when it last did.
void main() {
  late FakeCacheWarmer warmer;
  late FakeOfflineShelf shelf;
  late FakePhotoStore photos;
  late FakeDocumentDirectory documents;
  late DateTime now;
  late OfflineKeeper keeper;

  const householdId = 'h1';
  final jpeg = Uint8List.fromList([0xFF, 0xD8, 1]);

  setUp(() {
    warmer = FakeCacheWarmer();
    shelf = FakeOfflineShelf();
    photos = FakePhotoStore();
    documents = FakeDocumentDirectory();
    now = DateTime.utc(2026, 9, 29, 15);
    keeper = OfflineKeeper(
      cacheWarmer: warmer,
      shelf: shelf,
      photoStore: photos,
      documentDirectory: documents,
      householdId: householdId,
      request: (
        householdId: householdId,
        readsProfiles: true,
        healthOf: ['m-kid'],
      ),
      now: () => now,
    );
  });

  tearDown(() => keeper.dispose());

  test('starts as not saved', () {
    expect(keeper.status, isA<NotSavedOffline>());
  });

  test('saving reads the hub from the server, keeps every photo it points at '
      'and says when', () async {
    warmer.photoIds = {'photo-guide', 'photo-card'};
    photos.objects['photo-guide'] = jpeg;
    photos.objects['photo-card'] = jpeg;
    await keeper.saveNow();

    expect(warmer.requests.single.healthOf, ['m-kid']);
    expect(warmer.requests.single.readsProfiles, isTrue);
    // Storage reads the grant off the token, so the claims come first.
    expect(documents.syncCount, 1);
    expect(shelf.photos.keys, containsAll(['h1/photo-guide', 'h1/photo-card']));
    expect(shelf.stamps[householdId], now);
    expect((keeper.status as SavedOffline).savedAt, now);
  });

  test('says it is saving while it saves', () async {
    warmer.gate = Completer<void>();
    final saving = keeper.saveNow();
    await pumpEventQueue();
    expect(keeper.status, isA<SavingOffline>());
    warmer.gate!.complete();
    await saving;
    expect(keeper.status, isA<SavedOffline>());
  });

  test('a second save while one runs is the same save', () async {
    warmer.gate = Completer<void>();
    final first = keeper.saveNow();
    final second = keeper.saveNow();
    warmer.gate!.complete();
    await Future.wait([first, second]);
    expect(warmer.requests, hasLength(1));
  });

  test('a photo already on the shelf is never fetched again', () async {
    warmer.photoIds = {'photo-guide'};
    shelf.photos['h1/photo-guide'] = jpeg;
    await keeper.saveNow();
    expect(photos.reads, isEmpty);
  });

  test(
    'a photo removed since its record was read is simply not kept',
    () async {
      warmer.photoIds = {'photo-gone', 'photo-card'};
      photos.objects['photo-card'] = jpeg;
      await keeper.saveNow();
      expect(shelf.photos.keys, ['h1/photo-card']);
      expect(keeper.status, isA<SavedOffline>());
    },
  );

  test('no signal keeps what was saved before, and says so', () async {
    await keeper.saveNow();
    final before = now;
    now = now.add(const Duration(hours: 2));
    warmer.failWith = const UnavailableFailure();
    await keeper.saveNow();
    final failed = keeper.status as OfflineSaveFailed;
    expect(failed.isNoSignal, isTrue);
    expect(failed.savedAt, before);
    expect(shelf.stamps[householdId], before);
  });

  test('a phone that will not keep the photos says so', () async {
    warmer.photoIds = {'photo-card'};
    photos.objects['photo-card'] = jpeg;
    shelf.failWith = const NannyHubFailure(NannyHubProblem.cannotSaveOffline);
    await keeper.saveNow();
    final failed = keeper.status as OfflineSaveFailed;
    expect(failed.isNoSignal, isFalse);
    expect(failed.savedAt, isNull);
  });

  test('opening the app reads the last save, and saves again only when it is '
      'older than an hour', () async {
    shelf.stamps[householdId] = now.subtract(const Duration(minutes: 20));
    await keeper.open();
    expect(warmer.requests, isEmpty);
    expect(keeper.status, isA<SavedOffline>());

    now = now.add(const Duration(hours: 1));
    await keeper.open();
    expect(warmer.requests, hasLength(1));
    expect((keeper.status as SavedOffline).savedAt, now);
  });

  test('opening with nothing saved saves', () async {
    await keeper.open();
    expect(warmer.requests, hasLength(1));
  });

  test('forgetting takes everything off the phone', () async {
    warmer.photoIds = {'photo-card'};
    photos.objects['photo-card'] = jpeg;
    await keeper.saveNow();
    await keeper.forget();
    expect(shelf.cleared, [householdId]);
    expect(shelf.photos, isEmpty);
    expect(keeper.status, isA<NotSavedOffline>());
  });

  test('a changed grant changes what the next save reads', () async {
    keeper.follow((
      householdId: householdId,
      readsProfiles: false,
      healthOf: const [],
    ));
    await keeper.saveNow();
    expect(warmer.requests.single.readsProfiles, isFalse);
    expect(warmer.requests.single.healthOf, isEmpty);
  });
}
