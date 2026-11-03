import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/photos/jpeg_compressor.dart';
import '../../../shared/photos/photo_compressor.dart';
import '../../../shared/state/action_failure.dart';
import '../../documents/data/document_directory.dart';
import '../data/frame_photo_picker.dart';
import '../data/frame_photo_store.dart';
import '../model/frame_photo.dart';

final class FramePhotosController extends ChangeNotifier
    with ActionFailureHolder {
  FramePhotosController({
    required FramePhotoStore photoStore,
    required FramePhotoPicker photoPicker,
    required DocumentDirectory documentDirectory,
    required this.householdId,
    required this.uploaderUid,
    this._compressor = framePhotoCompressor,
  }) : _store = photoStore,
       _picker = photoPicker,
       _directory = documentDirectory {
    unawaited(_load());
  }

  static const framePhotoCompressor = JpegCompressor(
    maxEdge: 1920,
    jpegQuality: 80,
    maxBytes: FramePhoto.maxBytes,
    unreadable: FramePhotoFailure(FramePhotoProblem.photoUnreadable),
    tooLarge: FramePhotoFailure(FramePhotoProblem.photoTooLarge),
  );

  static const photoLimit = FramePhoto.albumLimit;
  static const heldLimit = 36;

  final FramePhotoStore _store;
  final FramePhotoPicker _picker;
  final DocumentDirectory _directory;
  final PhotoCompressor _compressor;
  final String householdId;
  final String uploaderUid;

  AsyncState<List<FramePhoto>> _photos = const AsyncLoading();
  final _thumbnails = <String, AsyncState<Uint8List>>{};
  FramePhotoProgress? _adding;
  FramePhotoAddReport? _lastAdd;
  String? _removingId;
  Future<void>? _access;
  var _isDisposed = false;

  AsyncState<List<FramePhoto>> get photos => _photos;

  List<FramePhoto> get _loaded => switch (_photos) {
    AsyncData(:final value) => value,
    _ => const [],
  };

  int get count => _loaded.length;

  bool get isLoaded => _photos is AsyncData<List<FramePhoto>>;

  bool get isEmpty => isLoaded && _loaded.isEmpty;

  bool get isFull => count >= photoLimit;

  FramePhotoProgress? get adding => _adding;

  bool get isAdding => _adding != null;

  FramePhotoAddReport? get lastAdd => _lastAdd;

  String? get removingId => _removingId;

  bool get isBusy => isAdding || _removingId != null;

  AsyncState<Uint8List> thumbnailOf(String photoId) =>
      _thumbnails[photoId] ?? const AsyncLoading();

  void ensureThumbnail(String photoId) {
    if (_thumbnails.containsKey(photoId)) return;
    _thumbnails[photoId] = const AsyncLoading();
    _letGoOfTheOldest();
    unawaited(_fetch(photoId));
  }

  void retryThumbnail(String photoId) {
    _thumbnails.remove(photoId);
    ensureThumbnail(photoId);
    _notify();
  }

  Future<void> retry() async {
    _photos = const AsyncLoading();
    _notify();
    await _load();
  }

  void dismissReport() {
    if (_lastAdd == null) return;
    _lastAdd = null;
    _notify();
  }

  Future<void> addFromLibrary() async {
    if (!isLoaded || isBusy) return;
    _lastAdd = null;
    final room = photoLimit - count;
    if (room <= 0) {
      recordFailure(const FramePhotoFailure(FramePhotoProblem.albumFull));
      return;
    }
    await runAction(() async {
      final picked = await _picker.pickMany(limit: room);
      if (picked.isEmpty) return;
      final taking = picked.take(room).toList();
      var added = 0;
      var skipped = 0;
      try {
        for (var index = 0; index < taking.length; index++) {
          _adding = (current: index + 1, total: taking.length);
          _notify();
          if (await _addOne(taking[index])) {
            added++;
          } else {
            skipped++;
          }
        }
      } finally {
        _adding = null;
        _lastAdd = (
          added: added,
          skipped: skipped,
          hitLimit: picked.length > room,
        );
        _notify();
      }
    });
  }

  Future<bool> remove(FramePhoto photo) async {
    if (isBusy) return false;
    _removingId = photo.id;
    _lastAdd = null;
    _notify();
    await runAction(() async {
      await _openAccess();
      await _store.remove(householdId, photo.id);
      _photos = AsyncData([
        for (final kept in _loaded)
          if (kept.id != photo.id) kept,
      ]);
      _thumbnails.remove(photo.id);
    });
    _removingId = null;
    _notify();
    return actionFailure == null;
  }

  Future<bool> _addOne(PickedPhoto picked) async {
    try {
      final photo = await _compressor.compress(await picked());
      await _openAccess();
      final stored = await _store.add(
        householdId,
        photo,
        uploaderUid: uploaderUid,
      );
      _photos = AsyncData([stored, ..._loaded]);
      _thumbnails[stored.id] = AsyncData(photo.bytes);
      _letGoOfTheOldest();
      return true;
    } on FramePhotoFailure catch (failure) {
      if (failure.problem == FramePhotoProblem.photoUnreadable ||
          failure.problem == FramePhotoProblem.photoTooLarge) {
        return false;
      }
      rethrow;
    }
  }

  Future<void> _load() async {
    try {
      await _openAccess();
      _photos = AsyncData(await _store.list(householdId));
    } on AppFailure catch (failure) {
      _photos = AsyncFailure(failure);
    }
    _notify();
  }

  Future<void> _fetch(String photoId) async {
    AsyncState<Uint8List> state;
    try {
      await _openAccess();
      state = AsyncData(await _store.bytes(householdId, photoId));
    } on AppFailure catch (failure) {
      state = AsyncFailure(failure);
    }
    if (!_thumbnails.containsKey(photoId)) return;
    _thumbnails[photoId] = state;
    _notify();
  }

  Future<void> _openAccess() async {
    final pending = _access ??= _directory.syncAccess();
    try {
      await pending;
    } on AppFailure {
      _access = null;
      rethrow;
    }
  }

  void _letGoOfTheOldest() {
    while (_thumbnails.length > heldLimit) {
      _thumbnails.remove(_thumbnails.keys.first);
    }
  }

  void _notify() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
