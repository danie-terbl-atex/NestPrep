import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/nanny_hub/model/photo_feed.dart';
import 'package:nestprep/features/nanny_hub/model/photo_update.dart';
import 'package:nestprep/features/nanny_hub/state/photo_feed_controller.dart';
import 'package:nestprep/features/nanny_hub/state/photo_library.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_documents.dart';
import '../../../support/fake_nanny_access.dart';
import '../../../support/fake_nanny_hub.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/nanny_fixtures.dart';

/// Photo updates (nanny-hub ADR-0004): a carer's photo reaches the parents'
/// feed, stored first and taken back if the update is refused.
void main() {
  late FakeShiftRepository shifts;
  late FakePhotoUpdateRepository updates;
  late FakePhotoStore store;
  late PhotoLibrary photos;
  late PhotoFeedController controller;

  final picked = Uint8List.fromList([1, 2, 3]);

  PhotoUpdate update(String id, {String by = NannyFixtures.nomsaMemberId}) =>
      PhotoUpdate(
        id: id,
        photoId: 'photo-$id',
        caption: 'Fort',
        childIds: const [Fixtures.kidMemberId],
        byMemberId: by,
        createdAt: DateTime.utc(2026, 9, 29, 14, 32),
      );

  PhotoFeedController feedFor({
    String memberId = NannyFixtures.nomsaMemberId,
    bool isFamily = false,
  }) => PhotoFeedController(
    photoUpdateRepository: updates,
    shiftRepository: shifts,
    photos: photos,
    householdId: 'h1',
    shiftId: 'shift-1',
    memberId: memberId,
    isFamily: isFamily,
  );

  setUp(() {
    shifts = FakeShiftRepository();
    updates = FakePhotoUpdateRepository();
    store = FakePhotoStore();
    photos = PhotoLibrary(
      photoStore: store,
      documentDirectory: FakeDocumentDirectory(),
      householdId: 'h1',
      uploaderUid: NannyFixtures.nomsaUid,
      compress: (bytes) async => bytes,
    );
    controller = feedFor();
  });

  tearDown(() async {
    controller.dispose();
    photos.dispose();
    await shifts.close();
    await updates.close();
  });

  test(
    'is loading until the shift and its photos have both answered',
    () async {
      shifts.shift.add(NannyFixtures.openShift);
      await pumpEventQueue();
      expect(controller.feed, isA<AsyncLoading<PhotoFeed>>());
      updates.updates.add([update('u2'), update('u1')]);
      await pumpEventQueue();
      final feed = (controller.feed as AsyncData<PhotoFeed>).value;
      expect(feed.isLive, isTrue);
      expect([for (final u in feed.updates) u.id], ['u2', 'u1']);
    },
  );

  test('asks the library for every photo in the feed', () async {
    shifts.shift.add(NannyFixtures.openShift);
    updates.updates.add([update('u1')]);
    await pumpEventQueue();
    expect(photos.stateOf('photo-u1'), isNot(isA<AsyncLoading<Uint8List>>()));
  });

  test('a shift that has ended is still a feed, no longer live', () async {
    shifts.shift.add(
      NannyFixtures.openShift.copyWith(
        status: 'ended',
        endedAt: DateTime.utc(2026),
      ),
    );
    updates.updates.add(const []);
    await pumpEventQueue();
    final feed = (controller.feed as AsyncData<PhotoFeed>).value;
    expect(feed.isLive, isFalse);
    expect(feed.isGone, isFalse);
  });

  test('a shift that is gone says so, not a failure', () async {
    shifts.shift.add(null);
    updates.updates.add(const []);
    await pumpEventQueue();
    expect((controller.feed as AsyncData<PhotoFeed>).value.isGone, isTrue);
  });

  test(
    'a failed read is the feed’s failure, and a retry reads again',
    () async {
      updates.updates.addError(const UnavailableFailure());
      await pumpEventQueue();
      expect(controller.feed, isA<AsyncFailure<PhotoFeed>>());
      await controller.retry();
      expect(controller.feed, isA<AsyncLoading<PhotoFeed>>());
      shifts.shift.add(NannyFixtures.openShift);
      updates.updates.add(const []);
      await pumpEventQueue();
      expect(controller.feed, isA<AsyncData<PhotoFeed>>());
    },
  );

  test('sending stores the photo first, then the update that points at it, '
      'stamped with the sender and the caption tidied', () async {
    final sent = await controller.send(
      picked,
      caption: '  Fort in the lounge  ',
      childIds: const [Fixtures.kidMemberId],
    );
    expect(sent, isTrue);
    final write = updates.sent.single;
    expect(store.objects[write.photoId], picked);
    expect(write.byMemberId, NannyFixtures.nomsaMemberId);
    expect(write.caption, 'Fort in the lounge');
    expect(write.childIds, [Fixtures.kidMemberId]);
    expect(write.shiftId, 'shift-1');
  });

  test('a blank caption is no caption', () async {
    await controller.send(picked, caption: '   ');
    expect(updates.sent.single.caption, isNull);
  });

  test(
    'an update the rules refuse takes its photo back out, and says why',
    () async {
      updates.failWritesWith = const PermissionDeniedFailure();
      final sent = await controller.send(picked);
      expect(sent, isFalse);
      expect(store.objects, isEmpty);
      expect(store.removed, hasLength(1));
      expect(controller.actionFailure, isA<PermissionDeniedFailure>());
    },
  );

  test('a photo that could not be stored sends no update', () async {
    store.failUploadsWith = const UnavailableFailure();
    expect(await controller.send(picked), isFalse);
    expect(updates.sent, isEmpty);
    expect(controller.actionFailure, isA<UnavailableFailure>());
  });

  test('a second tap while one is on its way is not a second photo', () async {
    updates.gate = Completer<void>();
    final first = controller.send(picked);
    await pumpEventQueue();
    expect(controller.isSending, isTrue);
    expect(await controller.send(picked), isFalse);
    updates.gate!.complete();
    expect(await first, isTrue);
    expect(updates.sent, hasLength(1));
    expect(controller.isSending, isFalse);
  });

  test('taking a photo back removes the update and its bytes', () async {
    store.objects['photo-u1'] = picked;
    await controller.remove(update('u1'));
    expect(updates.removed, ['u1']);
    expect(store.removed, ['photo-u1']);
  });

  test('the sender takes back their own while the shift is open; family '
      'any time', () {
    final mine = update('u1');
    final theirs = update('u2', by: 'm-somebody');
    expect(controller.mayRemove(mine, isShiftOpen: true), isTrue);
    expect(controller.mayRemove(mine, isShiftOpen: false), isFalse);
    expect(controller.mayRemove(theirs, isShiftOpen: true), isFalse);
    final family = feedFor(memberId: Fixtures.samMemberId, isFamily: true);
    addTearDown(family.dispose);
    expect(family.mayRemove(theirs, isShiftOpen: false), isTrue);
  });
}
