import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/best_effort.dart';
import '../data/document_store.dart';
import '../model/picked_document.dart';
import 'document_upload_state.dart';
import 'upload_destination.dart';

/// Adding one file: the bytes, then the row, in that order and only that order.
///
/// This is a separate thing from the controllers that hold the documents
/// because it is a separate thing to get wrong. An upload is long, it can be
/// stopped halfway, it can fail after the bytes have landed, and what it
/// leaves behind when it does is the difference between a document somebody
/// can delete and bytes nobody can see and nobody stops paying for (`BE-07`,
/// documents ADR-0001). The household's folders and the personal vaults share
/// it through an `UploadDestination`.
final class DocumentUploadRunner<T> {
  DocumentUploadRunner({
    required this._destination,
    required void Function() notifyChange,
    required void Function(AppFailure failure) reportFailure,
  }) : _onChange = notifyChange,
       _onFailure = reportFailure;

  final UploadDestination<T> _destination;
  final void Function() _onChange;
  final void Function(AppFailure failure) _onFailure;

  DocumentUploadState? _state;
  var _isPreparing = false;
  DocumentUpload? _inFlight;
  ({T details, PickedDocument file})? _pending;

  /// What is being added, or null when nothing is.
  DocumentUploadState? get state => _state;

  /// What the upload in flight, or the one that last failed, was for.
  T? get details => _pending?.details;

  /// Whether the last attempt left a file worth trying again with.
  bool get canRetry => _pending != null && _state == null;

  /// A scan is being composed into its file, before any byte is sent.
  bool get isPreparing => _isPreparing;

  Future<void> start({required T details, required PickedDocument file}) {
    _pending = (details: details, file: file);
    return _run();
  }

  /// Makes the file first — composing a scan takes a second or two — and then
  /// adds it. A file that could not be made is reported like any refusal.
  Future<void> prepareAndStart({
    required T details,
    required Future<PickedDocument> Function() prepare,
  }) async {
    _isPreparing = true;
    _onChange();
    final PickedDocument file;
    try {
      file = await prepare();
    } on AppFailure catch (failure) {
      _isPreparing = false;
      _onFailure(failure);
      return;
    }
    _isPreparing = false;
    await start(details: details, file: file);
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

    final documentId = _destination.mintId(pending.details);
    final upload = _destination.send(documentId, pending.file, pending.details);
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
    ({T details, PickedDocument file}) pending,
    String documentId,
  ) async {
    try {
      await _destination.record(documentId, pending.file, pending.details);
      _pending = null;
      _onChange();
    } on AppFailure catch (failure) {
      _onFailure(failure);
      await bestEffort(
        'orphaned document bytes',
        code: 'metadata-write-failed',
        run: () => _destination.discard(documentId, pending.details),
      );
    }
  }
}
