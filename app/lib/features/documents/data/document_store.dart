import 'dart:typed_data';

import '../model/picked_document.dart';

/// The bytes half: Cloud Storage, at `households/{id}/documents/{documentId}`.
///
/// Storage has no offline cache, so nothing here works without a connection —
/// which is why the metadata and the bytes are separate interfaces rather than
/// one repository. A document's name is in Firestore's cache on a train; its
/// contents are not (foundation ADR-0006, documents ADR-0001).
abstract interface class DocumentStore {
  /// Starts storing the bytes and hands back the upload to watch and cancel.
  ///
  /// [uploaderUid] is stamped onto the object, because Storage rules know uids
  /// and not member profiles — it is what lets the delete rule there agree with
  /// the Firestore rule on the metadata row of the same name.
  DocumentUpload upload({
    required String householdId,
    required String documentId,
    required String uploaderUid,
    required PickedDocument file,
  });

  /// The bytes, read through the authenticated SDK so the rules apply. Used for
  /// the in-app preview of an image.
  Future<Uint8List> read({
    required String householdId,
    required String documentId,
  });

  /// A link the device's own viewer can fetch, for a file the app cannot
  /// render. It authorises by possession rather than by rule, so it is handed
  /// straight to the platform and never shown or shared (documents ADR-0001).
  Future<Uri> openableLink({
    required String householdId,
    required String documentId,
  });

  Future<void> remove({
    required String householdId,
    required String documentId,
  });

  /// The largest preview the app will pull into memory. A document past this is
  /// opened outside instead of rendered; it is the same as the rules' cap, so
  /// nothing that was allowed in is unreadable once it is there.
  static const maxReadBytes = 20 * 1024 * 1024;
}

/// One upload in flight: something to watch, and something to stop.
abstract interface class DocumentUpload {
  /// How much of the file has been stored, from 0 to 1. The stream completes
  /// when every byte is there, and carries an `AppFailure` when it is not —
  /// including `DocumentProblem.uploadCancelled` when somebody stopped it.
  Stream<double> get progress;

  Future<void> cancel();
}
