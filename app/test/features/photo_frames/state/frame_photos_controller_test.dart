import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/photo_frames/model/frame_photo.dart';
import 'package:nestprep/features/photo_frames/state/frame_photos_controller.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_documents.dart';
import '../../../support/fake_photo_frames.dart';

void main() {
  late FakeFramePhotoStore store;
  late FakeFramePhotoPicker picker;
  late FakeFramePhotoCompressor compressor;
  late FakeDocumentDirectory directory;
  late FramePhotosController controller;

  Future<void> build([List<FramePhoto> album = const []]) async {
    store = FakeFramePhotoStore(album);
    controller = FramePhotoFixtures.controller(
      store: store,
      picker: picker,
      compressor: compressor,
      directory: directory,
    );
    await pumpEventQueue();
  }

  setUp(() {
    picker = FakeFramePhotoPicker();
    compressor = FakeFramePhotoCompressor();
    directory = FakeDocumentDirectory();
  });

  tearDown(() => controller.dispose());

  group('loading', () {
    test('opens Storage access once, then holds the album', () async {
      await build(FramePhotoFixtures.album(3));

      expect(directory.syncCount, 1);
      expect(controller.photos, isA<AsyncData<List<FramePhoto>>>());
      expect(controller.count, 3);
      expect(controller.isEmpty, isFalse);
    });

    test('an album that will not list is a failure with a retry', () async {
      store = FakeFramePhotoStore()
        ..failListWith = const PermissionDeniedFailure();
      controller = FramePhotoFixtures.controller(
        store: store,
        directory: directory,
      );
      await pumpEventQueue();
      expect(controller.photos, isA<AsyncFailure<List<FramePhoto>>>());
      expect(controller.isLoaded, isFalse);

      store.failListWith = null;
      await controller.retry();
      expect(controller.isEmpty, isTrue);
    });

    test('access that fails is asked for again on retry', () async {
      directory.failSyncWith = const UnavailableFailure();
      await build();
      expect(controller.photos, isA<AsyncFailure<List<FramePhoto>>>());

      directory.failSyncWith = null;
      await controller.retry();
      expect(directory.syncCount, 2);
      expect(controller.isLoaded, isTrue);
    });
  });

  group('adding', () {
    test('adds each picked photo in turn, newest first', () async {
      await build(FramePhotoFixtures.album(2));
      picker.pickPhotos(3);
      final progress = <FramePhotoProgress?>[];
      controller.addListener(() => progress.add(controller.adding));

      await controller.addFromLibrary();

      expect(store.added, hasLength(3));
      expect(controller.count, 5);
      expect(controller.photos, isA<AsyncData<List<FramePhoto>>>());
      final ids = (controller.photos as AsyncData<List<FramePhoto>>).value.map(
        (photo) => photo.id,
      );
      expect(ids.first, 'added-photo-0002');
      expect(progress.whereType<FramePhotoProgress>().toSet(), {
        (current: 1, total: 3),
        (current: 2, total: 3),
        (current: 3, total: 3),
      });
      expect(controller.adding, isNull);
      expect(controller.lastAdd, (added: 3, skipped: 0, hitLimit: false));
      expect(controller.actionFailure, isNull);
    });

    test('asks the library for no more than there is room for', () async {
      await build(FramePhotoFixtures.album(97));
      picker.pickPhotos(5);

      await controller.addFromLibrary();

      expect(picker.limits.single, 3);
      expect(store.added, hasLength(3));
      expect(controller.count, FramePhoto.albumLimit);
      expect(controller.isFull, isTrue);
      expect(controller.lastAdd, (added: 3, skipped: 0, hitLimit: true));
    });

    test('a full album says so and does not open the library', () async {
      await build(FramePhotoFixtures.album(FramePhoto.albumLimit));

      await controller.addFromLibrary();

      expect(picker.limits, isEmpty);
      expect(
        controller.actionFailure,
        isA<FramePhotoFailure>().having(
          (failure) => failure.problem,
          'problem',
          FramePhotoProblem.albumFull,
        ),
      );
    });

    test('a photo that cannot be used is skipped, the rest go on', () async {
      await build();
      picker.pickPhotos(3);
      compressor.refuse.add(1);

      await controller.addFromLibrary();

      expect(store.added, hasLength(2));
      expect(controller.lastAdd, (added: 2, skipped: 1, hitLimit: false));
      expect(controller.actionFailure, isNull);
    });

    test('a refused upload stops the run and keeps what landed', () async {
      await build();
      picker.pickPhotos(2);
      store.failAddsWith = const UnavailableFailure();

      await controller.addFromLibrary();

      expect(controller.actionFailure, isA<UnavailableFailure>());
      expect(controller.adding, isNull);
      expect(controller.lastAdd, (added: 0, skipped: 0, hitLimit: false));
      expect(controller.count, 0);
    });

    test('a library that will not open is said, not thrown', () async {
      await build();
      picker.failWith = const FramePhotoFailure(
        FramePhotoProblem.libraryUnavailable,
      );

      await controller.addFromLibrary();

      expect(controller.actionFailure, isA<FramePhotoFailure>());
    });

    test('backing out of the library changes nothing', () async {
      await build(FramePhotoFixtures.album(1));

      await controller.addFromLibrary();

      expect(controller.count, 1);
      expect(controller.lastAdd, isNull);
      expect(controller.actionFailure, isNull);
    });

    test('a second tap while adding is ignored', () async {
      await build();
      picker.pickPhotos(1);
      store.holdAdds = Completer<void>();

      final first = controller.addFromLibrary();
      await pumpEventQueue();
      expect(controller.isAdding, isTrue);
      await controller.addFromLibrary();
      expect(picker.limits, hasLength(1));

      store.holdAdds!.complete();
      await first;
      expect(controller.count, 1);
    });
  });

  group('removing', () {
    test('takes the photo out of the album', () async {
      final album = FramePhotoFixtures.album(2);
      await build(album);

      expect(await controller.remove(album.first), isTrue);

      expect(store.removed, [album.first.id]);
      expect(controller.count, 1);
    });

    test('a refused remove keeps the photo and says why', () async {
      final album = FramePhotoFixtures.album(1);
      await build(album);
      store.failRemovesWith = const PermissionDeniedFailure();

      expect(await controller.remove(album.single), isFalse);

      expect(controller.count, 1);
      expect(controller.actionFailure, isA<PermissionDeniedFailure>());
      expect(controller.removingId, isNull);
    });
  });

  group('thumbnails', () {
    test('fetched once when asked for', () async {
      final album = FramePhotoFixtures.album(1);
      await build(album);
      final id = album.single.id;
      expect(controller.thumbnailOf(id), isA<AsyncLoading<Object?>>());

      controller
        ..ensureThumbnail(id)
        ..ensureThumbnail(id);
      await pumpEventQueue();

      expect(store.read, [id]);
      expect(controller.thumbnailOf(id), isA<AsyncData<Object?>>());
    });

    test('one that failed is fetched again on retry', () async {
      final album = FramePhotoFixtures.album(1);
      await build(album);
      final id = album.single.id;
      store.failReadsWith = const UnavailableFailure();
      controller.ensureThumbnail(id);
      await pumpEventQueue();
      expect(controller.thumbnailOf(id), isA<AsyncFailure<Object?>>());

      store.failReadsWith = null;
      controller.retryThumbnail(id);
      await pumpEventQueue();
      expect(controller.thumbnailOf(id), isA<AsyncData<Object?>>());
    });

    test('a newly added photo shows without a fetch', () async {
      await build();
      picker.pickPhotos(1);
      await controller.addFromLibrary();
      final id =
          (controller.photos as AsyncData<List<FramePhoto>>).value.single.id;

      expect(controller.thumbnailOf(id), isA<AsyncData<Object?>>());
      expect(store.read, isEmpty);
    });
  });

  test('the compressor is the one the rule allows', () async {
    await build();
    const compressor = FramePhotosController.framePhotoCompressor;
    expect(compressor.maxEdge, 1920);
    expect(compressor.jpegQuality, 80);
    expect(compressor.maxBytes, FramePhoto.maxBytes);
  });
}
