import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/photo_frames/data/frame_photo_picker.dart';
import 'package:nestprep/features/photo_frames/data/frame_photo_store.dart';
import 'package:nestprep/features/photo_frames/data/frame_share_payload.dart';
import 'package:nestprep/features/photo_frames/data/photo_frame_directory.dart';
import 'package:nestprep/features/photo_frames/data/photo_frame_repository.dart';
import 'package:nestprep/features/photo_frames/model/frame_groceries.dart';
import 'package:nestprep/features/photo_frames/model/frame_panels.dart';
import 'package:nestprep/features/photo_frames/model/frame_photo.dart';
import 'package:nestprep/features/photo_frames/model/frame_screensaver.dart';
import 'package:nestprep/features/photo_frames/model/frame_share_item.dart';
import 'package:nestprep/features/photo_frames/model/photo_frame.dart';
import 'package:nestprep/features/photo_frames/state/frame_photos_controller.dart';
import 'package:nestprep/features/photo_frames/ui/frame_scanner.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/photos/compressed_photo.dart';
import 'package:nestprep/shared/photos/photo_compressor.dart';

import 'fake_documents.dart';
import 'fake_vault.dart';
import 'household_fixtures.dart';

final class FakePhotoFrameRepository implements PhotoFrameRepository {
  final _frames = StreamController<List<PhotoFrame>>.broadcast();

  AppFailure? failWrites;
  final updated =
      <
        ({
          String frameId,
          String name,
          FramePanels panels,
          FrameScreensaver screensaver,
          FrameGroceries? groceries,
        })
      >[];
  final unlinked = <String>[];

  void emit(List<PhotoFrame> frames) => _frames.add(frames);
  void failWith(Object error) => _frames.addError(error);
  bool get hasListener => _frames.hasListener;
  Future<void> close() => _frames.close();

  @override
  Stream<List<PhotoFrame>> watchFrames(String householdId) => _frames.stream;

  @override
  Future<void> updateFrame({
    required String householdId,
    required String frameId,
    required String name,
    required FramePanels panels,
    required FrameScreensaver screensaver,
    required FrameGroceries? groceries,
  }) async {
    _answer();
    updated.add((
      frameId: frameId,
      name: name,
      panels: panels,
      screensaver: screensaver,
      groceries: groceries,
    ));
  }

  @override
  Future<void> unlinkFrame({
    required String householdId,
    required String frameId,
  }) async {
    _answer();
    unlinked.add(frameId);
  }

  void _answer() {
    final failure = failWrites;
    if (failure != null) throw failure;
  }
}

final class FakePhotoFrameDirectory implements PhotoFrameDirectory {
  AppFailure? failWith;
  Completer<void>? holdCalls;
  final claimed = <({String code, String name, FramePanels panels})>[];
  final shared = <({String frameId, String url, String? title})>[];
  final sharedRecipes = <({String frameId, FrameShareRecipe recipe})>[];
  final payloads = <Map<String, Object?>>[];

  @override
  Future<String> claimPairing({
    required String householdId,
    required String code,
    required String name,
    required FramePanels panels,
  }) async {
    await holdCalls?.future;
    final failure = failWith;
    if (failure != null) throw failure;
    claimed.add((code: code, name: name, panels: panels));
    return 'frame-${claimed.length}';
  }

  @override
  Future<void> shareToFrame({
    required String householdId,
    required String frameId,
    required FrameShareItem item,
  }) async {
    await holdCalls?.future;
    final failure = failWith;
    if (failure != null) throw failure;
    payloads.add(
      frameSharePayload(householdId: householdId, frameId: frameId, item: item),
    );
    switch (item) {
      case FrameSharePage(:final page):
        shared.add((frameId: frameId, url: page.url!, title: page.title));
      case final FrameShareRecipe recipe:
        sharedRecipes.add((frameId: frameId, recipe: recipe));
    }
  }
}

final class FakeFrameScanner implements FrameScanner {
  ValueChanged<String>? _onScanned;

  void scan(String raw) => _onScanned?.call(raw);

  @override
  Widget build({required ValueChanged<String> onScanned}) {
    _onScanned = onScanned;
    return const _Viewfinder();
  }
}

class _Viewfinder extends StatelessWidget {
  const _Viewfinder();

  @override
  Widget build(BuildContext context) {
    final c = NestTheme.light().colors;
    return ColoredBox(
      color: c.ink,
      child: Center(
        child: Icon(
          LucideIcons.scanQrCode,
          size: NestSize.brandMarkLarge,
          color: c.surface,
        ),
      ),
    );
  }
}

abstract final class FrameFixtures {
  static DateTime get now => DateTime.now().toUtc();

  static PhotoFrame frame({
    String id = 'frame-kitchen',
    String name = 'Kitchen frame',
    FramePanels panels = const FramePanels(),
    FrameScreensaver screensaver = FrameScreensaver.off,
    FrameGroceries? groceries,
    DateTime? lastSeenAt,
    DateTime? linkedAt,
    List<String> accepts = const ['page', 'recipe'],
  }) => PhotoFrame(
    id: id,
    name: name,
    panels: panels,
    screensaver: screensaver,
    groceries: groceries,
    model: 'NestPrep Home',
    linkedBy: 'uid-sam',
    linkedAt: linkedAt ?? now.subtract(const Duration(days: 3)),
    lastSeenAt: lastSeenAt,
    accepts: accepts,
  );
}

final class FakeFramePhotoStore implements FramePhotoStore {
  FakeFramePhotoStore([List<FramePhoto> photos = const []])
    : photos = [...photos];

  final List<FramePhoto> photos;
  final added = <CompressedPhoto>[];
  final removed = <String>[];
  final read = <String>[];
  AppFailure? failListWith;
  AppFailure? failAddsWith;
  AppFailure? failRemovesWith;
  AppFailure? failReadsWith;
  Completer<void>? holdList;
  Completer<void>? holdAdds;
  var _next = 0;

  @override
  Future<List<FramePhoto>> list(String householdId) async {
    await holdList?.future;
    final failure = failListWith;
    if (failure != null) throw failure;
    return [...photos];
  }

  @override
  Future<Uint8List> bytes(String householdId, String photoId) async {
    read.add(photoId);
    final failure = failReadsWith;
    if (failure != null) throw failure;
    return onePixelPng;
  }

  @override
  Future<FramePhoto> add(
    String householdId,
    CompressedPhoto photo, {
    required String uploaderUid,
  }) async {
    await holdAdds?.future;
    final failure = failAddsWith;
    if (failure != null) throw failure;
    added.add(photo);
    final stored = FramePhoto(
      id: 'added-photo-${(_next++).toString().padLeft(4, '0')}',
      uploadedByUid: uploaderUid,
      createdAt: DateTime.utc(2026, 10, 25),
    );
    photos.insert(0, stored);
    return stored;
  }

  @override
  Future<void> remove(String householdId, String photoId) async {
    final failure = failRemovesWith;
    if (failure != null) throw failure;
    removed.add(photoId);
    photos.removeWhere((photo) => photo.id == photoId);
  }
}

final class FakeFramePhotoPicker implements FramePhotoPicker {
  List<PickedPhoto> next = const [];
  AppFailure? failWith;
  final limits = <int>[];

  void pickPhotos(int count) => next = [
    for (var index = 0; index < count; index++) () async => onePixelPng,
  ];

  @override
  Future<List<PickedPhoto>> pickMany({required int limit}) async {
    limits.add(limit);
    final failure = failWith;
    if (failure != null) throw failure;
    return next;
  }
}

final class FakeFramePhotoCompressor implements PhotoCompressor {
  final refuse = <int>{};
  var _calls = 0;

  @override
  Future<CompressedPhoto> compress(Uint8List original) async {
    if (refuse.contains(_calls++)) {
      throw const FramePhotoFailure(FramePhotoProblem.photoUnreadable);
    }
    return CompressedPhoto(bytes: original, width: 1, height: 1);
  }
}

abstract final class FramePhotoFixtures {
  static List<FramePhoto> album(int count) => [
    for (var index = 0; index < count; index++)
      FramePhoto(
        id: 'album-photo-${index.toString().padLeft(4, '0')}',
        uploadedByUid: Fixtures.samUid,
        createdAt: DateTime.utc(2026, 10, 2).subtract(Duration(hours: index)),
      ),
  ];

  static FramePhotosController controller({
    FakeFramePhotoStore? store,
    FakeFramePhotoPicker? picker,
    PhotoCompressor? compressor,
    FakeDocumentDirectory? directory,
  }) => FramePhotosController(
    photoStore: store ?? FakeFramePhotoStore(),
    photoPicker: picker ?? FakeFramePhotoPicker(),
    documentDirectory: directory ?? FakeDocumentDirectory(),
    householdId: Fixtures.householdId,
    uploaderUid: Fixtures.samUid,
    compressor: compressor ?? FakeFramePhotoCompressor(),
  );
}
