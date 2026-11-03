import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/photo_frames/model/frame_photo.dart';
import 'package:nestprep/features/photo_frames/state/frame_photos_controller.dart';
import 'package:nestprep/features/photo_frames/ui/frame_photo_tile.dart';
import 'package:nestprep/features/photo_frames/ui/frame_photos_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_photo_frames.dart';
import '../../../support/pump_screen.dart';

void main() {
  late FakeFramePhotoStore store;
  late FakeFramePhotoPicker picker;
  late FakeFramePhotoCompressor compressor;
  late FramePhotosController controller;

  void build(List<FramePhoto> album) {
    store = FakeFramePhotoStore(album);
    controller = FramePhotoFixtures.controller(
      store: store,
      picker: picker,
      compressor: compressor,
    );
  }

  setUp(() {
    picker = FakeFramePhotoPicker();
    compressor = FakeFramePhotoCompressor();
  });

  tearDown(() => controller.dispose());

  Future<void> pump(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    double scale = 1,
  }) async {
    await pumpScreen(
      tester,
      const FramePhotosScreen(),
      providers: [
        ChangeNotifierProvider<FramePhotosController>.value(value: controller),
      ],
      brightness: brightness,
      textScale: scale,
    );
    await tester.pumpAndSettle();
  }

  Finder addButton() =>
      find.widgetWithText(NestButton, PhotoFrameCopy.addPhotos);

  testWidgets('holds the layout while it loads', (tester) async {
    build(const []);
    store.holdList = Completer<void>();
    await pumpScreen(
      tester,
      const FramePhotosScreen(),
      providers: [
        ChangeNotifierProvider<FramePhotosController>.value(value: controller),
      ],
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('loading')), findsOneWidget);
    expect(find.text(PhotoFrameCopy.photosTitle), findsOneWidget);
    store.holdList!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('an empty album invites the first photos', (tester) async {
    build(const []);
    picker.pickPhotos(2);
    await pump(tester);

    expect(find.text(PhotoFrameCopy.photosEmptyTitle), findsOneWidget);
    await tester.tap(find.text(PhotoFrameCopy.addPhotos));
    await tester.pumpAndSettle();

    expect(store.added, hasLength(2));
    expect(find.byType(FramePhotoTile), findsNWidgets(2));
    expect(find.text(PhotoFrameCopy.photoCount(2)), findsOneWidget);
  });

  testWidgets('an album that will not list offers a retry', (tester) async {
    build(const []);
    store.failListWith = const UnavailableFailure();
    await pump(tester);

    expect(find.text(AppCopy.retry), findsOneWidget);
    store.failListWith = null;
    await tester.tap(find.text(AppCopy.retry));
    await tester.pumpAndSettle();
    expect(find.text(PhotoFrameCopy.photosEmptyTitle), findsOneWidget);
  });

  testWidgets('the album: explainer, count and a grid of photos', (
    tester,
  ) async {
    build(FramePhotoFixtures.album(4));
    await pump(tester);

    expect(find.text(PhotoFrameCopy.photosIntro), findsOneWidget);
    expect(find.text(PhotoFrameCopy.photoCount(4)), findsOneWidget);
    expect(find.byType(FramePhotoTile), findsNWidgets(4));
    expect(find.byType(Image), findsNWidgets(4));
    expect(find.bySemanticsLabel(PhotoFrameCopy.photoLabel(1)), findsOneWidget);
  });

  testWidgets('a photo that will not load says so, and retries', (
    tester,
  ) async {
    build(FramePhotoFixtures.album(1));
    store.failReadsWith = const UnavailableFailure();
    await pump(tester);

    expect(find.text(PhotoFrameCopy.photoFailed), findsOneWidget);
    store.failReadsWith = null;
    await tester.tap(find.byIcon(LucideIcons.refreshCw));
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('adding shows how far it has got', (tester) async {
    build(FramePhotoFixtures.album(1));
    picker.pickPhotos(3);
    store.holdAdds = Completer<void>();
    await pump(tester);

    await tester.tap(addButton());
    await tester.pump();
    await tester.pump();
    expect(find.text(PhotoFrameCopy.adding(1, 3)), findsOneWidget);

    store.holdAdds!.complete();
    await tester.pumpAndSettle();
    expect(find.text(PhotoFrameCopy.photoCount(4)), findsOneWidget);
    expect(addButton(), findsOneWidget);
  });

  testWidgets('photos it could not use are counted once it is done', (
    tester,
  ) async {
    build(const []);
    picker.pickPhotos(3);
    compressor.refuse.add(0);
    await pump(tester);

    await tester.tap(find.text(PhotoFrameCopy.addPhotos));
    await tester.pumpAndSettle();

    expect(
      find.text(
        PhotoFrameCopy.addReport((added: 2, skipped: 1, hitLimit: false)),
      ),
      findsOneWidget,
    );
    await tester.tap(find.text(PhotoFrameCopy.done));
    await tester.pumpAndSettle();
    expect(find.byType(NestBanner), findsNothing);
  });

  testWidgets('a full album cannot take more, and says so', (tester) async {
    build(FramePhotoFixtures.album(FramePhoto.albumLimit));
    await pump(tester);

    expect(
      find.text(PhotoFrameCopy.photoCount(FramePhoto.albumLimit)),
      findsOneWidget,
    );
    expect(find.text(PhotoFrameCopy.albumFullHint), findsOneWidget);
    expect(tester.widget<NestButton>(addButton()).onPressed, isNull);
  });

  testWidgets('a refused upload is said in a banner', (tester) async {
    build(FramePhotoFixtures.album(1));
    picker.pickPhotos(1);
    store.failAddsWith = const PermissionDeniedFailure();
    await pump(tester);

    await tester.tap(addButton());
    await tester.pumpAndSettle();

    expect(
      find.text(AppCopy.failure(const PermissionDeniedFailure())),
      findsOneWidget,
    );
  });

  group('removing', () {
    testWidgets('a tapped photo comes off after asking', (tester) async {
      final album = FramePhotoFixtures.album(2);
      build(album);
      await pump(tester);

      await tester.tap(find.byType(FramePhotoTile).first);
      await tester.pumpAndSettle();
      expect(find.text(PhotoFrameCopy.removePhotoConfirm), findsOneWidget);
      await tester.tap(
        find.widgetWithText(NestButton, PhotoFrameCopy.removePhoto),
      );
      await tester.pumpAndSettle();

      expect(store.removed, [album.first.id]);
      expect(find.byType(FramePhotoTile), findsOneWidget);
      expect(find.text(PhotoFrameCopy.photoCount(1)), findsOneWidget);
    });

    testWidgets('and stays when kept', (tester) async {
      build(FramePhotoFixtures.album(1));
      await pump(tester);

      await tester.tap(find.byType(FramePhotoTile));
      await tester.pumpAndSettle();
      await tester.tap(find.text(PhotoFrameCopy.keep));
      await tester.pumpAndSettle();

      expect(store.removed, isEmpty);
      expect(find.byType(FramePhotoTile), findsOneWidget);
    });
  });

  testWidgets('survives dark at 200% text on a 360-wide phone', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    build(const []);
    await pump(tester, brightness: Brightness.dark, scale: 2);
    expect(find.text(PhotoFrameCopy.photosEmptyTitle), findsOneWidget);
    expect(tester.takeException(), isNull);

    final empty = controller;
    build(FramePhotoFixtures.album(7));
    store.failReadsWith = const UnavailableFailure();
    picker.pickPhotos(2);
    compressor.refuse.add(0);
    await pump(tester, brightness: Brightness.dark, scale: 2);
    empty.dispose();
    expect(find.text(PhotoFrameCopy.photoFailed), findsWidgets);
    expect(tester.takeException(), isNull);

    store.failReadsWith = null;
    await tester.tap(addButton());
    await tester.pumpAndSettle();
    expect(
      find.text(
        PhotoFrameCopy.addReport((added: 1, skipped: 1, hitLimit: false)),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    final added = find.byKey(const ValueKey('added-photo-0000'));
    await tester.scrollUntilVisible(added, 200);
    await tester.pumpAndSettle();
    await tester.tap(added);
    await tester.pumpAndSettle();
    expect(find.text(PhotoFrameCopy.removePhotoConfirm), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
