import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/best_effort.dart';
import '../../documents/data/document_directory.dart';
import '../data/photo_compressor.dart';
import '../data/photo_store.dart';

/// The hub's photos for the screens under it: fetched once each, held while
/// the hub is open, and stored — compressed first — when somebody adds one
/// (nanny-hub ADR-0003). A widget asks for a photo's state and never fetches
/// (`FE-05`); the controller that knows which photos a screen shows asks for
/// them.
///
/// Storage rules read the grant off the ID token, so before the first read or
/// upload the account's claims are refreshed through the same callable the
/// documents feature uses (`ENG-01`). If that fails, every photo says so —
/// the words around them still read, because they come from Firestore.
final class PhotoLibrary extends ChangeNotifier {
  PhotoLibrary({
    required PhotoStore photoStore,
    required DocumentDirectory documentDirectory,
    required this.householdId,
    required this.uploaderUid,
    this._compress = PhotoCompressor.compress,
  }) : _store = photoStore,
       _directory = documentDirectory;

  /// More photos than one hub shows; past it the oldest is let go.
  static const heldLimit = 60;

  final PhotoStore _store;
  final DocumentDirectory _directory;
  final Future<Uint8List> Function(Uint8List bytes) _compress;
  final String householdId;
  final String uploaderUid;

  final _photos = <String, AsyncState<Uint8List>>{};
  Future<void>? _access;
  var _isDisposed = false;

  /// Loading until asked for and fetched; a failure the photo tile shows.
  AsyncState<Uint8List> stateOf(String photoId) =>
      _photos[photoId] ?? const AsyncLoading();

  /// Fetches each photo not already held or on its way.
  void ensure(Iterable<String?> photoIds) {
    for (final photoId in photoIds) {
      if (photoId == null || _photos.containsKey(photoId)) continue;
      _photos[photoId] = const AsyncLoading();
      unawaited(_fetch(photoId));
    }
    _letGoOfTheOldest();
  }

  /// Fetches a photo again after it failed.
  void retry(String photoId) {
    _photos.remove(photoId);
    ensure([photoId]);
    _notify();
  }

  /// Compresses, stores and holds a picked photo, and answers its id. Throws
  /// the `AppFailure` that stopped it, for the controller's banner.
  Future<String> store(Uint8List picked) async {
    final jpeg = await _compress(picked);
    await _openAccess();
    final photoId = _store.newPhotoId();
    await _store.upload(
      householdId: householdId,
      photoId: photoId,
      uploaderUid: uploaderUid,
      jpeg: jpeg,
    );
    _photos[photoId] = AsyncData(jpeg);
    _notify();
    return photoId;
  }

  /// Removes a photo nothing points at any more — replaced, or orphaned by a
  /// write that failed after it was stored. Nobody is waiting on it, so a
  /// failure is a log line rather than a banner; the orphan stays findable
  /// under the household's nanny-hub folder (`BE-07`).
  Future<void> discard(String photoId) async {
    _photos.remove(photoId);
    await bestEffort(
      'discard nanny photo',
      code: 'storage',
      run: () async {
        await _openAccess();
        await _store.remove(householdId: householdId, photoId: photoId);
      },
    );
  }

  Future<void> _fetch(String photoId) async {
    try {
      await _openAccess();
      final bytes = await _store.read(
        householdId: householdId,
        photoId: photoId,
      );
      _photos[photoId] = AsyncData(bytes);
    } on AppFailure catch (failure) {
      _photos[photoId] = AsyncFailure(failure);
    }
    _notify();
  }

  /// The claims refresh, once per hub visit — and again after a failure, so
  /// "try again" means it.
  Future<void> _openAccess() async {
    final pending = _access ??= _directory.syncAccess();
    try {
      await pending;
    } on AppFailure {
      _access = null;
      rethrow;
    }
  }

  void _letGoOfTheOldest() {
    while (_photos.length > heldLimit) {
      _photos.remove(_photos.keys.first);
    }
  }

  void _notify() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
