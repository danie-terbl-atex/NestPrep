import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/best_effort.dart';
import '../data/document_repository.dart';
import '../data/document_store.dart';
import '../model/picked_document.dart';
import 'document_upload_state.dart';

/// Adding one file: the bytes, then the row, in that order and only that order.
///
/// This is a separate thing from the controller that holds the library because
/// it is a separate thing to get wrong. An upload is long, it can be stopped
/// halfway, it can fail after the bytes have landed, and what it leaves behind
/// when it does is the difference between a document somebody can delete and
/// bytes nobody can see and nobody stops paying for (`BE-07`, documents
/// ADR-0001).
final class DocumentUploadRunner {
  DocumentUploadRunner({
    required DocumentRepository documentRepository,
    required DocumentStore documentStore,
    required this.householdId,
    required this.memberId,
    required this.viewerUid,
    required void Function() notifyChange,
    required void Function(AppFailure failure) reportFailure,
  }) : _repository = documentRepository,
       _store = documentStore,
       _onChange = notifyChange,
       _onFailure = reportFailure;

  final DocumentRepository _repository;
  final DocumentStore _store;
  final String householdId;
  final String memberId;
  final String viewerUid;
  final void Function() _onChange;
  final void Function(AppFailure failure) _onFailure;

  DocumentUploadState? _state;
  DocumentUpload? _inFlight;
  ({String folderId, PickedDocument file})? _pending;

  /// What is being added, or null when nothing is.
  DocumentUploadState? get state => _state;

  /// Whether the last attempt left a file worth trying again with.
  bool get canRetry => _pending != null && _state == null;

  Future<void> start({required String folderId, required PickedDocument file}) {
    _pending = (folderId: folderId, file: file);
    return _run();
  }

  Future<void> retry() => _run();

  Future<void> cancel() async {
    // The task reports the cancellation through its own stream, so it reaches
    // the screen the same way every other refusal does (`ENG-10`).
    await _inFlight?.cancel();
  }

  /// Gives up on the file that failed, so the screen stops offering to retry.
  void forget() {
    if (_pending == null) return;
    _pending = null;
    _onChange();
  }

  Future<void> _run() async {
    final pending = _pending;
    if (pending == null || _state != null) return;

    final documentId = _repository.newDocumentId(householdId);
    final upload = _store.upload(
      householdId: householdId,
      documentId: documentId,
      uploaderUid: viewerUid,
      file: pending.file,
    );
    _inFlight = upload;
    _state = DocumentUploadState(fileName: pending.file.name, fraction: 0);
    _onChange();

    final stored = await _sendBytes(upload);
    _inFlight = null;
    _state = null;
    if (!stored) {
      _onChange();
      return;
    }
    await _recordStoredBytes(pending, documentId);
  }

  /// Watches the bytes go. False means they did not, and the refusal has
  /// already been handed on.
  Future<bool> _sendBytes(DocumentUpload upload) async {
    try {
      await for (final fraction in upload.progress) {
        _state = _state?.at(fraction);
        _onChange();
      }
      return true;
    } on AppFailure catch (failure) {
      _onFailure(failure);
      return false;
    }
  }

  /// The bytes are stored; the row that makes them findable is not yet.
  ///
  /// If this write fails the object is an orphan — invisible, and billed — so
  /// it is deleted again. That delete is genuinely best-effort: nothing on
  /// screen waits for it, and the object's name is the id the row would have
  /// had, so a sweep can still find whatever it misses (`ENG-10`).
  Future<void> _recordStoredBytes(
    ({String folderId, PickedDocument file}) pending,
    String documentId,
  ) async {
    try {
      await _repository.addDocument(
        householdId: householdId,
        documentId: documentId,
        folderId: pending.folderId,
        name: pending.file.name,
        contentType: pending.file.contentType,
        sizeBytes: pending.file.sizeBytes,
        uploadedBy: memberId,
      );
      _pending = null;
      _onChange();
    } on AppFailure catch (failure) {
      _onFailure(failure);
      await bestEffort(
        'orphaned document bytes',
        code: 'metadata-write-failed',
        run: () =>
            _store.remove(householdId: householdId, documentId: documentId),
      );
    }
  }
}
