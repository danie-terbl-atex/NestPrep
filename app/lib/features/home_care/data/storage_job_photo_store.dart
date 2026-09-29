import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

import '../../../shared/failure/app_failure.dart';
import '../../../shared/failure/storage_failure_mapper.dart';
import '../../../shared/photos/compressed_photo.dart';
import '../model/home_care_photo.dart';
import 'job_photo_store.dart';

final class StorageJobPhotoStore implements JobPhotoStore {
  StorageJobPhotoStore(this._storage);

  /// Where a job's photo lives; the folder is the job's id, so an orphan is
  /// findable by listing the jobs (home-care ADR-0003).
  static String pathFor({
    required String householdId,
    required String jobId,
    required String photoId,
  }) => 'households/$householdId/homeCareJobs/$jobId/$photoId';

  /// The key `storage.rules` checks the uploader against — the same one the
  /// documents use.
  static const uploaderKey = 'uploadedByUid';

  final FirebaseStorage _storage;

  Reference _ref(String householdId, String jobId, String photoId) => _storage
      .ref(pathFor(householdId: householdId, jobId: jobId, photoId: photoId));

  @override
  Future<void> upload({
    required String householdId,
    required String jobId,
    required String photoId,
    required String uploaderUid,
    required CompressedPhoto photo,
  }) async {
    try {
      await _ref(householdId, jobId, photoId).putData(
        photo.bytes,
        SettableMetadata(
          contentType: CompressedPhoto.contentType,
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
    required String jobId,
    required String photoId,
  }) async {
    try {
      final bytes = await _ref(
        householdId,
        jobId,
        photoId,
      ).getData(HomeCarePhoto.maxBytes);
      if (bytes == null) throw const NotFoundFailure();
      return bytes;
    } on FirebaseException catch (error) {
      throw failureFromStorage(error);
    }
  }

  @override
  Future<void> remove({
    required String householdId,
    required String jobId,
    required String photoId,
  }) async {
    try {
      await _ref(householdId, jobId, photoId).delete();
    } on FirebaseException catch (error) {
      throw failureFromStorage(error);
    }
  }
}
