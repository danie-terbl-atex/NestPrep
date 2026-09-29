import 'dart:typed_data';

import '../model/compressed_photo.dart';

/// The bytes of a job's photos, in Cloud Storage at
/// `households/{h}/homeCareJobs/{jobId}/{photoId}` (home-care ADR-0003).
///
/// Storage has no offline cache, so these need a connection even when the
/// job itself is in Firestore's.
abstract interface class JobPhotoStore {
  /// Stores a compressed photo, stamped with [uploaderUid] — the key the
  /// rules check the uploader against.
  Future<void> upload({
    required String householdId,
    required String jobId,
    required String photoId,
    required String uploaderUid,
    required CompressedPhoto photo,
  });

  Future<Uint8List> read({
    required String householdId,
    required String jobId,
    required String photoId,
  });

  Future<void> remove({
    required String householdId,
    required String jobId,
    required String photoId,
  });
}
