import 'dart:async';

import 'package:firebase_storage/firebase_storage.dart';

import 'document_store.dart';
import 'storage_failure_mapper.dart';

/// One `UploadTask`, as fractions of the file stored — shared by the
/// household's documents and the personal vaults, which upload the same way to
/// different paths.
///
/// The task's own stream reports bytes and a state; a screen wants neither. It
/// wants a number between nought and one, a completion, and a failure it can
/// put words to — so the translation happens here, at the edge, and the
/// controller never sees a `TaskSnapshot`.
final class StorageUpload implements DocumentUpload {
  StorageUpload(this._task) {
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
