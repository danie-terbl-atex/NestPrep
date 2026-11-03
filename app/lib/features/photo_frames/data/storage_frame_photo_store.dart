import 'dart:math';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

import '../../../shared/failure/app_failure.dart';
import '../../../shared/photos/compressed_photo.dart';
import '../model/frame_photo.dart';
import 'frame_photo_store.dart';
import 'photo_frame_failure_mapper.dart';

final class StorageFramePhotoStore implements FramePhotoStore {
  StorageFramePhotoStore(this._storage, {Random? random})
    : _random = random ?? Random.secure();

  static const uploaderKey = 'uploadedByUid';
  static const cacheLimit = 24;

  static const _alphabet =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

  final FirebaseStorage _storage;
  final Random _random;
  final _cache = <String, Uint8List>{};

  static String folderFor(String householdId) =>
      'households/$householdId/framePhotos';

  static String pathFor(String householdId, String photoId) =>
      '${folderFor(householdId)}/$photoId';

  Reference _ref(String householdId, String photoId) =>
      _storage.ref(pathFor(householdId, photoId));

  @override
  Future<List<FramePhoto>> list(String householdId) => _guarded(() async {
    final listing = await _storage.ref(folderFor(householdId)).listAll();
    final photos = await Future.wait([
      for (final item in listing.items)
        if (FramePhoto.idPattern.hasMatch(item.name)) _photoAt(item),
    ]);
    return photos..sort(_newestFirst);
  });

  @override
  Future<Uint8List> bytes(String householdId, String photoId) =>
      _guarded(() async {
        final key = pathFor(householdId, photoId);
        final cached = _cache.remove(key);
        if (cached != null) return _cache[key] = cached;
        final bytes = await _ref(
          householdId,
          photoId,
        ).getData(FramePhoto.maxBytes);
        if (bytes == null) throw const NotFoundFailure();
        _keep(key, bytes);
        return bytes;
      });

  @override
  Future<FramePhoto> add(
    String householdId,
    CompressedPhoto photo, {
    required String uploaderUid,
  }) => _guarded(() async {
    final photoId = _newPhotoId();
    final snapshot = await _ref(householdId, photoId).putData(
      photo.bytes,
      SettableMetadata(
        contentType: CompressedPhoto.contentType,
        customMetadata: {uploaderKey: uploaderUid},
      ),
    );
    _keep(pathFor(householdId, photoId), photo.bytes);
    return FramePhoto(
      id: photoId,
      uploadedByUid: uploaderUid,
      createdAt: snapshot.metadata?.timeCreated ?? DateTime.now(),
    );
  });

  @override
  Future<void> remove(String householdId, String photoId) => _guarded(() async {
    await _ref(householdId, photoId).delete();
    _cache.remove(pathFor(householdId, photoId));
  });

  Future<FramePhoto> _photoAt(Reference item) async {
    final metadata = await item.getMetadata();
    return FramePhoto(
      id: item.name,
      uploadedByUid: metadata.customMetadata?[uploaderKey],
      createdAt: metadata.timeCreated,
    );
  }

  static int _newestFirst(FramePhoto a, FramePhoto b) {
    final aAt = a.createdAt;
    final bAt = b.createdAt;
    if (aAt == null || bAt == null) {
      return aAt == bAt ? a.id.compareTo(b.id) : (aAt == null ? 1 : -1);
    }
    final byTime = bAt.compareTo(aAt);
    return byTime != 0 ? byTime : a.id.compareTo(b.id);
  }

  String _newPhotoId() => String.fromCharCodes([
    for (var index = 0; index < 20; index++)
      _alphabet.codeUnitAt(_random.nextInt(_alphabet.length)),
  ]);

  void _keep(String key, Uint8List bytes) {
    _cache[key] = bytes;
    while (_cache.length > cacheLimit) {
      _cache.remove(_cache.keys.first);
    }
  }

  Future<T> _guarded<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on FirebaseException catch (error) {
      throw failureFromFramePhotoStorage(error);
    }
  }
}
