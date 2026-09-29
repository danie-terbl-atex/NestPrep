import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/state/action_failure.dart';
import '../data/offline_access_check.dart';
import '../data/offline_copy_store.dart';
import '../data/pdf_page_renderer.dart';
import '../model/household_document.dart';
import '../model/offline_copy.dart';
import '../model/offline_shelf.dart';
import '../model/vault_document.dart';
import 'offline_copy_source.dart';
import 'vault_lock_controller.dart';

/// The documents kept on this phone for this household (documents ADR-0007),
/// behind the same lock as the vaults.
///
/// It follows the lock the way the vaults do: unlocking reads the encrypted
/// list, locking drops it — so not even a name is in memory while the phone's
/// lock stands between a stranger and the screen. Each time the list is read,
/// every copy is checked against the server, and the ones this person can no
/// longer open are deleted.
final class OfflineCopiesController extends ChangeNotifier
    with ActionFailureHolder {
  OfflineCopiesController({
    required this._store,
    required OfflineAccessCheck accessCheck,
    required this._source,
    required PdfPageRenderer pdfPageRenderer,
    required this.lock,
    required this.householdId,
    required this.uid,
    DateTime Function()? now,
  }) : _check = accessCheck,
       _renderer = pdfPageRenderer,
       _now = now ?? DateTime.now {
    lock.addListener(_followLock);
    _followLock();
  }

  final OfflineCopyStore _store;
  final OfflineAccessCheck _check;
  final OfflineCopySource _source;
  final PdfPageRenderer _renderer;
  final VaultLockController lock;
  final String householdId;
  final String uid;
  final DateTime Function() _now;

  AsyncState<OfflineShelf> _shelf = const AsyncLoading();
  var _isOpen = false;
  var _hasChecked = false;
  final _saving = <String>{};

  /// What is kept on this phone. Loading while locked.
  AsyncState<OfflineShelf> get shelf => _shelf;

  /// Whether the server has confirmed every copy since the list was opened.
  bool get hasChecked => _hasChecked;

  OfflineShelf? get _loaded => switch (_shelf) {
    AsyncData(:final value) => value,
    _ => null,
  };

  /// Whether this document is kept here — false while locked, when the list
  /// is not in memory to ask.
  bool holds({required String? ownerMemberId, required String documentId}) =>
      _loaded?.holds(ownerMemberId: ownerMemberId, documentId: documentId) ??
      false;

  bool isSaving(String documentId) => _saving.contains(documentId);

  void _followLock() {
    if (lock.isUnlocked && !_isOpen) {
      _isOpen = true;
      unawaited(_load());
    } else if (!lock.isUnlocked && _isOpen) {
      _isOpen = false;
      _hasChecked = false;
      _shelf = const AsyncLoading();
      clearFailureQuietly();
      notifyListeners();
    }
  }

  Future<void> retry() => _load();

  Future<void> _load() async {
    try {
      final copies = await _store.list(uid);
      if (!_isOpen) return;
      _publish(copies);
      await _revalidate(copies);
    } on AppFailure catch (failure) {
      if (!_isOpen) return;
      _shelf = AsyncFailure(failure);
      notifyListeners();
    }
  }

  void _publish(List<OfflineCopy> copies) {
    if (_isDisposed) return;
    _shelf = AsyncData(
      OfflineShelf([
        for (final copy in copies)
          if (copy.householdId == householdId) copy,
      ]),
    );
    notifyListeners();
  }

  /// Asks the server about each copy of this household's, one at a time
  /// (at most twenty), and deletes those it refuses or no longer has.
  Future<void> _revalidate(List<OfflineCopy> copies) async {
    final lost = <OfflineCopy>[];
    for (final copy in copies.where((c) => c.householdId == householdId)) {
      if (await _check.check(copy) == OfflineAccess.lost) lost.add(copy);
    }
    if (lost.isNotEmpty) await _store.remove(uid, lost);
    if (!_isOpen) return;
    _hasChecked = true;
    _publish(lost.isEmpty ? copies : await _store.list(uid));
  }

  Future<void> saveHouseholdDocument(HouseholdDocument document) => _save(
    document.id,
    () => _source.ofHouseholdDocument(document, now: _now().toUtc()),
  );

  Future<void> saveVaultDocument(VaultDocument document) => _save(
    document.id,
    () => _source.ofVaultDocument(document, now: _now().toUtc()),
  );

  /// Asks for the phone's lock first when it is shut — a copy is only ever
  /// made, like it is only ever opened, behind it.
  Future<void> _save(
    String documentId,
    Future<(OfflineCopy, Uint8List)> Function() fetch,
  ) async {
    if (!lock.isUnlocked) await lock.unlock();
    if (!lock.isUnlocked || _saving.contains(documentId)) return;
    _saving.add(documentId);
    notifyListeners();
    await runAction(() async {
      lock.touch();
      // The cap is per account on this phone, across every household.
      final everything = OfflineShelf(await _store.list(uid));
      if (everything.isFull) {
        throw const DocumentFailure(DocumentProblem.offlineLimitReached);
      }
      final (copy, bytes) = await fetch();
      await _store.save(uid, copy, bytes);
      _publish(await _store.list(uid));
    });
    _saving.remove(documentId);
    notifyListeners();
  }

  Future<void> remove(OfflineCopy copy) => runAction(() async {
    lock.touch();
    await _store.remove(uid, [copy]);
    _publish(await _store.list(uid));
  });

  /// Removes the copy of one document, found by where it lives — what a
  /// document's own sheet knows.
  Future<void> removeDocument({
    required String? ownerMemberId,
    required String documentId,
  }) async {
    final copy = _loaded?.copies
        .where(
          (copy) =>
              copy.documentId == documentId &&
              copy.ownerMemberId == ownerMemberId,
        )
        .firstOrNull;
    if (copy != null) await remove(copy);
  }

  Future<void> removeAll() => runAction(() async {
    lock.touch();
    await _store.remove(uid, _loaded?.copies ?? const []);
    _publish(await _store.list(uid));
  });

  /// The copy's pages as pictures, drawn by the app. One that will not
  /// decrypt is deleted and reported — it is never shown half-read.
  Future<List<Uint8List>> openPages(OfflineCopy copy) async {
    lock.touch();
    try {
      final bytes = await _store.read(uid, copy);
      return copy.isImage ? [bytes] : await _renderer.render(bytes);
    } on DocumentFailure catch (failure) {
      if (failure.problem == DocumentProblem.offlineCopyUnreadable) {
        await _store.remove(uid, [copy]);
        _publish(await _store.list(uid));
      }
      rethrow;
    }
  }

  var _isDisposed = false;

  /// A save or a check can finish after somebody has left Documents; what it
  /// did is on disk, and there is no screen left to tell.
  @override
  void notifyListeners() {
    if (!_isDisposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    lock.removeListener(_followLock);
    super.dispose();
  }
}
