import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

import '../../../shared/failure/app_failure.dart';
import '../model/picked_document.dart';
import 'document_store.dart';
import 'storage_failure_mapper.dart';
import 'storage_upload.dart';

final class StorageDocumentStore implements DocumentStore {
  StorageDocumentStore(this._storage);

  /// The object's name is the metadata document's id (documents ADR-0001).
  static String pathFor({
    required String householdId,
    required String documentId,
  }) => 'households/$householdId/documents/$documentId';

  /// The key `storage.rules` checks the uploader against. Storage rules know
  /// uids and not member profiles.
  static const uploaderKey = 'uploadedByUid';

  final FirebaseStorage _storage;

  Reference _ref(String householdId, String documentId) =>
      _storage.ref(pathFor(householdId: householdId, documentId: documentId));

  @override
  DocumentUpload upload({
    required String householdId,
    required String documentId,
    required String uploaderUid,
    required PickedDocument file,
  }) {
    final task = _ref(householdId, documentId).putData(
      file.bytes,
      SettableMetadata(
        contentType: file.contentType,
        customMetadata: {uploaderKey: uploaderUid},
      ),
    );
    return StorageUpload(task);
  }

  @override
  Future<Uint8List> read({
    required String householdId,
    required String documentId,
  }) async {
    try {
      final bytes = await _ref(
        householdId,
        documentId,
      ).getData(DocumentStore.maxReadBytes);
      if (bytes == null) throw const NotFoundFailure();
      return bytes;
    } on FirebaseException catch (error) {
      throw failureFromStorage(error);
    }
  }

  @override
  Future<Uri> openableLink({
    required String householdId,
    required String documentId,
  }) async {
    try {
      return Uri.parse(await _ref(householdId, documentId).getDownloadURL());
    } on FirebaseException catch (error) {
      throw failureFromStorage(error);
    }
  }

  @override
  Future<void> remove({
    required String householdId,
    required String documentId,
  }) async {
    try {
      await _ref(householdId, documentId).delete();
    } on FirebaseException catch (error) {
      throw failureFromStorage(error);
    }
  }
}
