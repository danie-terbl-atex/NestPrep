import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/failure/firebase_failure_mapper.dart';
import '../../../shared/firestore/typed_collection.dart';
import '../../../shared/time/calendar_date.dart';
import '../model/document_folder.dart';
import '../model/household_document.dart';
import 'document_repository.dart';

final class FirestoreDocumentRepository implements DocumentRepository {
  FirestoreDocumentRepository(this._firestore);

  static const householdsPath = 'households';
  static const foldersPath = 'documentFolders';
  static const documentsPath = 'documents';

  final FirebaseFirestore _firestore;

  CollectionReference<DocumentFolder> _folders(String householdId) =>
      typedCollection(
        _firestore
            .collection(householdsPath)
            .doc(householdId)
            .collection(foldersPath),
        fromJson: DocumentFolder.fromJson,
        toJson: (folder) => folder.toJson(),
      );

  CollectionReference<HouseholdDocument> _documents(String householdId) =>
      typedCollection(
        _firestore
            .collection(householdsPath)
            .doc(householdId)
            .collection(documentsPath),
        fromJson: HouseholdDocument.fromJson,
        toJson: (document) => document.toJson(),
      );

  @override
  Stream<List<DocumentFolder>> watchFolders(String householdId) =>
      _folders(householdId)
          .orderBy('name')
          .limit(DocumentRepository.folderLimit)
          .snapshots()
          .map(_foldersIn)
          .handleError((Object error) => throw failureFromFirebase(error));

  @override
  Stream<List<HouseholdDocument>> watchDocuments(String householdId) =>
      _documents(householdId)
          // Newest first, and no filter by folder: one listener cannot
          // disagree with itself while a write is pending, and the split
          // happens on the client (documents ADR-0001).
          .orderBy('uploadedAt', descending: true)
          .limit(DocumentRepository.documentLimit)
          .snapshots()
          .map(_documentsIn)
          .handleError((Object error) => throw failureFromFirebase(error));

  @override
  String newDocumentId(String householdId) => _documents(householdId).doc().id;

  @override
  Future<void> createFolder({
    required String householdId,
    required String name,
    required String createdBy,
  }) {
    final folders = _folders(householdId);
    final document = folders.doc();
    return _guarded(
      () => document.set(
        DocumentFolder(id: document.id, name: name, createdBy: createdBy),
      ),
    );
  }

  @override
  Future<void> renameFolder({
    required String householdId,
    required String folderId,
    required String name,
  }) => _guarded(
    () => _folders(householdId).doc(folderId).update({'name': name}),
  );

  @override
  Future<void> addDocument({
    required String householdId,
    required String documentId,
    required String folderId,
    required String name,
    required String contentType,
    required int sizeBytes,
    required String uploadedBy,
  }) => _guarded(
    () => _documents(householdId)
        .doc(documentId)
        .set(
          HouseholdDocument(
            id: documentId,
            folderId: folderId,
            name: name,
            contentType: contentType,
            sizeBytes: sizeBytes,
            uploadedBy: uploadedBy,
          ),
        ),
  );

  @override
  Future<void> editDocument({
    required String householdId,
    required String documentId,
    required String name,
    required String folderId,
    required List<String> tags,
    required CalendarDate? expiresOn,
  }) => _guarded(
    () => _documents(householdId).doc(documentId).update({
      'name': name,
      'folderId': folderId,
      'tags': tags,
      'expiresOn': expiresOn?.iso,
    }),
  );

  @override
  Future<void> removeDocument({
    required String householdId,
    required String documentId,
  }) => _guarded(() => _documents(householdId).doc(documentId).delete());

  List<DocumentFolder> _foldersIn(QuerySnapshot<DocumentFolder> snapshot) => [
    for (final document in snapshot.docs) document.data(),
  ];

  List<HouseholdDocument> _documentsIn(
    QuerySnapshot<HouseholdDocument> snapshot,
  ) => [for (final document in snapshot.docs) document.data()];

  Future<void> _guarded(Future<void> Function() write) async {
    try {
      await write();
    } on FirebaseException catch (error) {
      throw failureFromFirebase(error);
    }
  }
}
