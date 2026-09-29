import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

import '../../../shared/failure/app_failure.dart';
import '../../../shared/failure/storage_failure_mapper.dart';
import '../model/picked_document.dart';
import 'document_store.dart';
import 'storage_document_store.dart';
import 'storage_upload.dart';
import 'vault_store.dart';

final class StorageVaultStore implements VaultStore {
  StorageVaultStore(this._storage);

  /// The object's name is its metadata row's id, under its owner (documents
  /// ADR-0002). `storage.rules` reads the owner from this path.
  static String pathFor({
    required String householdId,
    required String ownerMemberId,
    required String documentId,
  }) => 'households/$householdId/vaults/$ownerMemberId/$documentId';

  final FirebaseStorage _storage;

  Reference _ref(String householdId, String ownerMemberId, String documentId) =>
      _storage.ref(
        pathFor(
          householdId: householdId,
          ownerMemberId: ownerMemberId,
          documentId: documentId,
        ),
      );

  @override
  DocumentUpload upload({
    required String householdId,
    required String ownerMemberId,
    required String documentId,
    required String uploaderUid,
    required PickedDocument file,
  }) {
    final task = _ref(householdId, ownerMemberId, documentId).putData(
      file.bytes,
      SettableMetadata(
        contentType: file.contentType,
        customMetadata: {StorageDocumentStore.uploaderKey: uploaderUid},
      ),
    );
    return StorageUpload(task);
  }

  @override
  Future<Uint8List> read({
    required String householdId,
    required String ownerMemberId,
    required String documentId,
  }) async {
    try {
      final bytes = await _ref(
        householdId,
        ownerMemberId,
        documentId,
      ).getData(DocumentStore.maxReadBytes);
      if (bytes == null) throw const NotFoundFailure();
      return bytes;
    } on FirebaseException catch (error) {
      throw failureFromStorage(error);
    }
  }

  @override
  Future<void> remove({
    required String householdId,
    required String ownerMemberId,
    required String documentId,
  }) async {
    try {
      await _ref(householdId, ownerMemberId, documentId).delete();
    } on FirebaseException catch (error) {
      throw failureFromStorage(error);
    }
  }
}
