import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/failure/app_failure.dart';
import '../../documents/data/document_directory.dart';
import '../data/cache_warmer.dart';
import '../data/offline_shelf.dart';
import '../data/photo_store.dart';
import '../model/offline_status.dart';

/// Keeps the hub ready for no signal (nanny-hub ADR-0007): the records in
/// Firestore's cache, read fresh from the server, and the photos a carer needs
/// in a hurry on the phone's own shelf. It lives on the household shell, so it
/// saves when a carer opens the app, when a shift starts and when a booked
/// shift's window opens — not only when somebody happens to open the hub.
final class OfflineKeeper extends ChangeNotifier {
  OfflineKeeper({
    required CacheWarmer cacheWarmer,
    required this._shelf,
    required PhotoStore photoStore,
    required DocumentDirectory documentDirectory,
    required this.householdId,
    required this._request,
    required this._now,
  }) : _warmer = cacheWarmer,
       _photos = photoStore,
       _directory = documentDirectory;

  /// How old a save may be before opening the app saves again.
  static const freshFor = Duration(hours: 1);

  final CacheWarmer _warmer;
  final OfflineShelf _shelf;
  final PhotoStore _photos;
  final DocumentDirectory _directory;
  final DateTime Function() _now;
  final String householdId;

  WarmRequest _request;
  OfflineStatus _status = const NotSavedOffline();
  Future<void>? _saving;
  var _isDisposed = false;

  OfflineStatus get status => _status;

  /// The children's profiles or a grant changed: the next save reads what the
  /// viewer may now read.
  void follow(WarmRequest request) => _request = request;

  /// Reads what an earlier visit saved, and saves again when that is older
  /// than [freshFor] — what opening the app does for a carer.
  Future<void> open() async {
    try {
      final savedAt = await _shelf.savedAt(householdId);
      if (savedAt != null) _set(SavedOffline(savedAt));
    } on AppFailure catch (failure) {
      _set(OfflineSaveFailed(failure));
      return;
    }
    await saveIfStale();
  }

  Future<void> saveIfStale() async {
    final savedAt = _status.savedAt;
    if (savedAt != null && _now().difference(savedAt) < freshFor) return;
    await saveNow();
  }

  /// Saves everything now; a second call while one is running waits for it
  /// rather than starting another.
  Future<void> saveNow() => _saving ??= _save().whenComplete(() {
    _saving = null;
  });

  /// Takes everything off the phone: a carer kept to their shifts, whose
  /// window just closed (nanny-hub ADR-0006).
  Future<void> forget() async {
    await _saving;
    try {
      await _shelf.clear(householdId);
      _set(const NotSavedOffline());
    } on AppFailure catch (failure) {
      _set(OfflineSaveFailed(failure, savedAt: _status.savedAt));
    }
  }

  Future<void> _save() async {
    final before = _status.savedAt;
    _set(SavingOffline(savedAt: before));
    try {
      final photoIds = await _warmer.warm(_request);
      if (photoIds.isNotEmpty) await _directory.syncAccess();
      for (final photoId in photoIds) {
        await _keep(photoId);
      }
      final at = _now();
      await _shelf.markSaved(householdId, at);
      _set(SavedOffline(at));
    } on AppFailure catch (failure) {
      _set(OfflineSaveFailed(failure, savedAt: before));
    }
  }

  /// A photo already on the shelf is never fetched twice: a photo's bytes
  /// never change under its id (nanny-hub ADR-0003). One removed since its
  /// record was read is simply not kept.
  Future<void> _keep(String photoId) async {
    if (await _shelf.hasPhoto(householdId: householdId, photoId: photoId)) {
      return;
    }
    try {
      final jpeg = await _photos.read(
        householdId: householdId,
        photoId: photoId,
      );
      await _shelf.keepPhoto(
        householdId: householdId,
        photoId: photoId,
        jpeg: jpeg,
      );
    } on NotFoundFailure {
      return;
    }
  }

  void _set(OfflineStatus status) {
    _status = status;
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
