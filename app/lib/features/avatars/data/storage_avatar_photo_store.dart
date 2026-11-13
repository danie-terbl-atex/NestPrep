import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

import '../../../shared/failure/storage_failure_mapper.dart';
import '../../../shared/log/app_log.dart';
import '../../../shared/photos/compressed_photo.dart';
import '../../../shared/photos/kept_photo_files.dart';
import 'avatar_photo_store.dart';

final class StorageAvatarPhotoStore implements AvatarPhotoStore {
  StorageAvatarPhotoStore(this._storage);

  static const uploaderKey = 'uploadedByUid';
  static const maxBytes = 512 * 1024;
  static const referenceMaxBytes = 2 * 1024 * 1024;
  static const readMaxBytes = 2 * 1024 * 1024;

  static String pathFor({
    required String householdId,
    required String memberId,
    required String hash,
  }) => '${prefixFor(householdId)}$memberId/$hash.jpg';

  static String prefixFor(String householdId) =>
      'households/$householdId/avatars/';

  static String inboxPathFor({
    required String householdId,
    required String memberId,
    required String inboxId,
  }) => '${prefixFor(householdId)}$memberId/inbox/$inboxId.jpg';

  final FirebaseStorage _storage;
  final _kept = KeptPhotoFiles('avatars');
  final _memory = <String, Uint8List>{};
  final _requests = <String, Future<Uint8List?>>{};

  @override
  Uint8List? kept({
    required String householdId,
    required String memberId,
    required String hash,
  }) =>
      keptAt(pathFor(householdId: householdId, memberId: memberId, hash: hash));

  @override
  Future<Uint8List?> read({
    required String householdId,
    required String memberId,
    required String hash,
  }) =>
      readAt(pathFor(householdId: householdId, memberId: memberId, hash: hash));

  @override
  Uint8List? keptAt(String path) => _memory[path];

  @override
  Future<Uint8List?> readAt(String path) {
    if (!path.startsWith('households/') || !path.endsWith('.jpg')) {
      return Future.value();
    }
    return _requests.putIfAbsent(path, () async {
      final bytes = await _fetch(path);
      if (bytes == null) {
        _requests.removeWhere((asked, _) => asked == path);
      } else {
        _memory[path] = bytes;
      }
      return bytes;
    });
  }

  @override
  Future<void> uploadReference({
    required String householdId,
    required String memberId,
    required String inboxId,
    required String uploaderUid,
    required Uint8List bytes,
  }) => _put(
    inboxPathFor(
      householdId: householdId,
      memberId: memberId,
      inboxId: inboxId,
    ),
    bytes: bytes,
    uploaderUid: uploaderUid,
  );

  @override
  Future<void> upload({
    required String householdId,
    required String memberId,
    required String hash,
    required String uploaderUid,
    required Uint8List bytes,
  }) async {
    final path = pathFor(
      householdId: householdId,
      memberId: memberId,
      hash: hash,
    );
    await _put(path, bytes: bytes, uploaderUid: uploaderUid);
    _memory[path] = bytes;
    _requests[path] = Future.value(bytes);
  }

  Future<void> _put(
    String path, {
    required Uint8List bytes,
    required String uploaderUid,
  }) async {
    try {
      await _storage
          .ref(path)
          .putData(
            bytes,
            SettableMetadata(
              contentType: CompressedPhoto.contentType,
              customMetadata: {uploaderKey: uploaderUid},
            ),
          );
    } on FirebaseException catch (error) {
      throw failureFromStorage(error);
    }
  }

  Future<Uint8List?> _fetch(String path) async {
    try {
      return await _kept.read(
        path,
        orFetch: () => _storage.ref(path).getData(readMaxBytes),
      );
    } on Exception catch (error) {
      AppLog.failure('avatar photo', code: 'unavailable', error: error);
      return null;
    }
  }
}
