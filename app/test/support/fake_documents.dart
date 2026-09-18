import 'dart:async';
import 'dart:typed_data';

import 'package:nestprep/features/documents/data/document_directory.dart';
import 'package:nestprep/features/documents/data/document_opener.dart';
import 'package:nestprep/features/documents/data/document_picker.dart';
import 'package:nestprep/features/documents/data/document_repository.dart';
import 'package:nestprep/features/documents/data/document_store.dart';
import 'package:nestprep/features/documents/model/document_folder.dart';
import 'package:nestprep/features/documents/model/household_document.dart';
import 'package:nestprep/features/documents/model/picked_document.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

/// Everything behind the documents controller, faked: the metadata, the bytes,
/// the two callables, the device's picker and the device's viewer.
///
/// They live in one file because they are one substitution — the boundary the
/// controller talks across — the way `fake_auth.dart` holds the two halves of a
/// session. Nothing here pumps a Firebase SDK (foundation ADR-0006).

final class FakeDocumentRepository implements DocumentRepository {
  final _folders = StreamController<List<DocumentFolder>>.broadcast();
  final _documents = StreamController<List<HouseholdDocument>>.broadcast();

  /// Set to make the next write fail, the way a rules denial does.
  AppFailure? failWritesWith;

  /// Set to fail only the row written after an upload, which is the case that
  /// leaves orphaned bytes behind.
  AppFailure? failAddDocumentWith;

  var _nextId = 0;
  final createdFolders = <String>[];
  final renamedFolders = <({String folderId, String name})>[];
  final added = <({String documentId, String folderId, String name})>[];
  final edited = <({String documentId, String name, String folderId})>[];
  final removed = <String>[];

  void emitFolders(List<DocumentFolder> folders) => _folders.add(folders);
  void emitDocuments(List<HouseholdDocument> documents) =>
      _documents.add(documents);
  void failFoldersWith(Object error) => _folders.addError(error);
  void failDocumentsWith(Object error) => _documents.addError(error);

  Future<void> close() async {
    await _folders.close();
    await _documents.close();
  }

  @override
  Stream<List<DocumentFolder>> watchFolders(String householdId) =>
      _folders.stream;

  @override
  Stream<List<HouseholdDocument>> watchDocuments(String householdId) =>
      _documents.stream;

  @override
  String newDocumentId(String householdId) => 'doc-${++_nextId}';

  @override
  Future<void> createFolder({
    required String householdId,
    required String name,
    required String createdBy,
  }) async {
    _refuseIfAsked();
    createdFolders.add(name);
  }

  @override
  Future<void> renameFolder({
    required String householdId,
    required String folderId,
    required String name,
  }) async {
    _refuseIfAsked();
    renamedFolders.add((folderId: folderId, name: name));
  }

  @override
  Future<void> addDocument({
    required String householdId,
    required String documentId,
    required String folderId,
    required String name,
    required String contentType,
    required int sizeBytes,
    required String uploadedBy,
  }) async {
    final failure = failAddDocumentWith;
    if (failure != null) throw failure;
    _refuseIfAsked();
    added.add((documentId: documentId, folderId: folderId, name: name));
  }

  @override
  Future<void> editDocument({
    required String householdId,
    required String documentId,
    required String name,
    required String folderId,
  }) async {
    _refuseIfAsked();
    edited.add((documentId: documentId, name: name, folderId: folderId));
  }

  @override
  Future<void> removeDocument({
    required String householdId,
    required String documentId,
  }) async {
    _refuseIfAsked();
    removed.add(documentId);
  }

  void _refuseIfAsked() {
    final failure = failWritesWith;
    if (failure != null) throw failure;
  }
}

final class FakeDocumentStore implements DocumentStore {
  /// The upload the next `upload` hands back, so a test drives progress,
  /// failure and cancellation by hand.
  FakeDocumentUpload? nextUpload;

  AppFailure? failReadWith;
  AppFailure? failRemoveWith;
  Uint8List bytes = Uint8List.fromList([1, 2, 3]);
  Uri link = Uri.parse('https://example.invalid/letter.pdf');

  final uploads = <({String documentId, String uploaderUid, String name})>[];
  final removedBytes = <String>[];

  @override
  DocumentUpload upload({
    required String householdId,
    required String documentId,
    required String uploaderUid,
    required PickedDocument file,
  }) {
    uploads.add((
      documentId: documentId,
      uploaderUid: uploaderUid,
      name: file.name,
    ));
    return nextUpload ??= FakeDocumentUpload();
  }

  @override
  Future<Uint8List> read({
    required String householdId,
    required String documentId,
  }) async {
    final failure = failReadWith;
    if (failure != null) throw failure;
    return bytes;
  }

  @override
  Future<Uri> openableLink({
    required String householdId,
    required String documentId,
  }) async => link;

  @override
  Future<void> remove({
    required String householdId,
    required String documentId,
  }) async {
    final failure = failRemoveWith;
    if (failure != null) throw failure;
    removedBytes.add(documentId);
  }
}

final class FakeDocumentUpload implements DocumentUpload {
  final _progress = StreamController<double>();
  var isCancelled = false;

  @override
  Stream<double> get progress => _progress.stream;

  @override
  Future<void> cancel() async {
    isCancelled = true;
    _progress.addError(const DocumentFailure(DocumentProblem.uploadCancelled));
    await _progress.close();
  }

  void emit(double fraction) => _progress.add(fraction);

  Future<void> finish() => _progress.close();

  Future<void> fail(AppFailure failure) async {
    _progress.addError(failure);
    await _progress.close();
  }
}

final class FakeDocumentDirectory implements DocumentDirectory {
  AppFailure? failSyncWith;
  AppFailure? failDeleteWith;
  var syncCount = 0;
  final deletedFolders = <String>[];

  @override
  Future<void> syncAccess() async {
    syncCount++;
    final failure = failSyncWith;
    if (failure != null) throw failure;
  }

  @override
  Future<void> deleteFolder({
    required String householdId,
    required String folderId,
  }) async {
    final failure = failDeleteWith;
    if (failure != null) throw failure;
    deletedFolders.add(folderId);
  }
}

final class FakeDocumentPicker implements DocumentPicker {
  /// What the next pick returns. Null is somebody backing out, which is a
  /// choice and not a failure.
  PickedDocument? next;
  var pickCount = 0;

  @override
  Future<PickedDocument?> pickOne() async {
    pickCount++;
    return next;
  }
}

final class FakeDocumentOpener implements DocumentOpener {
  var willOpen = true;
  final opened = <Uri>[];

  @override
  Future<bool> open(Uri link) async {
    opened.add(link);
    return willOpen;
  }
}

/// A file somebody chose, of a type and size the rules keep.
PickedDocument pickedDocument({
  String name = 'Term letter.pdf',
  String contentType = 'application/pdf',
  int sizeBytes = 1024,
}) => PickedDocument(
  name: name,
  contentType: contentType,
  bytes: Uint8List(sizeBytes),
);
