import 'dart:math';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

import '../../../shared/failure/app_failure.dart';
import '../../documents/data/storage_failure_mapper.dart';
import '../model/nanny_limits.dart';
import 'photo_store.dart';

final class StoragePhotoStore implements PhotoStore {
  StoragePhotoStore(this._storage, {Random? random})
    : _random = random ?? Random.secure();

  /// The key `storage.rules` checks the uploader against — the same key the
  /// documents feature stamps (`ENG-01`).
  static const uploaderKey = 'uploadedByUid';

  static const _alphabet =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

  final FirebaseStorage _storage;
  final Random _random;

  static String pathFor({
    required String householdId,
    required String photoId,
  }) => 'households/$householdId/nannyHub/$photoId';

  Reference _ref(String householdId, String photoId) =>
      _storage.ref(pathFor(householdId: householdId, photoId: photoId));

  @override
  String newPhotoId() => String.fromCharCodes([
    for (var index = 0; index < 20; index++)
      _alphabet.codeUnitAt(_random.nextInt(_alphabet.length)),
  ]);

  @override
  Future<void> upload({
    required String householdId,
    required String photoId,
    required String uploaderUid,
    required Uint8List jpeg,
  }) async {
    try {
      await _ref(householdId, photoId).putData(
        jpeg,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {uploaderKey: uploaderUid},
        ),
      );
    } on FirebaseException catch (error) {
      throw failureFromStorage(error);
    }
  }

  @override
  Future<Uint8List> read({
    required String householdId,
    required String photoId,
  }) async {
    try {
      final bytes = await _ref(
        householdId,
        photoId,
      ).getData(NannyLimits.photoBytes);
      if (bytes == null) throw const NotFoundFailure();
      return bytes;
    } on FirebaseException catch (error) {
      throw failureFromStorage(error);
    }
  }

  @override
  Future<void> remove({
    required String householdId,
    required String photoId,
  }) async {
    try {
      await _ref(householdId, photoId).delete();
    } on FirebaseException catch (error) {
      throw failureFromStorage(error);
    }
  }
}
