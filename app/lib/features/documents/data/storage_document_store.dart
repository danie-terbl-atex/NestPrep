import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

import '../../../shared/failure/app_failure.dart';
import '../model/picked_document.dart';
import 'document_store.dart';
import 'storage_failure_mapper.dart';

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
    return _TaskUpload(task);
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

/// One `UploadTask`, as fractions of the file stored.
///
/// The task's own stream reports bytes and a state; a screen wants neither. It
/// wants a number between nought and one, a completion, and a failure it can
/// put words to — so the translation happens here, at the edge, and the
/// controller never sees a `TaskSnapshot`.
final class _TaskUpload implements DocumentUpload {
  _TaskUpload(this._task) {
    _subscription = _task.snapshotEvents.listen(
      _onSnapshot,
      onError: _onError,
      onDone: _finish,
    );
  }

  final UploadTask _task;
  final _progress = StreamController<double>();
  StreamSubscription<TaskSnapshot>? _subscription;
  var _isClosed = false;

  @override
  Stream<double> get progress => _progress.stream;

  @override
  Future<void> cancel() async {
    // The task reports the cancellation through its own stream, so the failure
    // reaches the screen the same way every other one does (`ENG-10`).
    await _task.cancel();
  }

  void _onSnapshot(TaskSnapshot snapshot) {
    if (_isClosed) return;
    final total = snapshot.totalBytes;
    _progress.add(total <= 0 ? 0 : snapshot.bytesTransferred / total);
    if (snapshot.state == TaskState.success) _finish();
  }

  void _onError(Object error) {
    if (_isClosed) return;
    _isClosed = true;
    _progress.addError(failureFromStorage(error));
    unawaited(_close());
  }

  void _finish() {
    if (_isClosed) return;
    _isClosed = true;
    unawaited(_close());
  }

  Future<void> _close() async {
    await _subscription?.cancel();
    _subscription = null;
    await _progress.close();
  }
}
