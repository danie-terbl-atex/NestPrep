import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../shared/log/app_log.dart';
import '../../../shared/photos/kept_photo_files.dart';
import '../../../shared/time/calendar_date.dart';
import 'kept_lunch_photo_places.dart';
import 'lunch_photo_source.dart';

/// `lunchPhoto` (lunch-box ADR-0015): the Function finds or makes the photo
/// and names where it is in Storage; the bytes are kept on the phone by that
/// name, which never changes for a combination, so each is fetched once.
/// The name is kept too (ADR-0029), so a box the phone has pictured before
/// skips the Function and opens from the kept file.
final class CallableLunchPhotoSource implements LunchPhotoSource {
  CallableLunchPhotoSource(this._functions, this._storage);

  final FirebaseFunctions _functions;
  final FirebaseStorage _storage;
  final _requests = <String, Future<Uint8List?>>{};
  final _kept = KeptPhotoFiles('lunch_photos');
  final _places = KeptLunchPhotoPlaces();

  static const _timeout = Duration(seconds: 130);
  static const _pendingWait = Duration(seconds: 5);
  static const _pendingTries = 12;
  static const _largest = 4 * 1024 * 1024;

  @override
  Future<Uint8List?> photoFor({
    required String householdId,
    required String childId,
    required CalendarDate date,
    required String signature,
  }) {
    final key = '$householdId/$childId/${date.iso}/$signature';
    return _requests.putIfAbsent(key, () async {
      final photo = await _fetch(householdId, childId, date, signature);
      if (photo == null) _forget(key);
      return photo;
    });
  }

  void _forget(String key) {
    _requests.remove(key);
  }

  Future<Uint8List?> _fetch(
    String householdId,
    String childId,
    CalendarDate date,
    String signature,
  ) async {
    try {
      final known = await _places.pathOf(
        householdId: householdId,
        childId: childId,
        date: date,
        signature: signature,
      );
      final kept = known == null ? null : await _readKnown(known);
      if (kept != null) return kept;
      final path = await _pathOf(householdId, childId, date);
      if (path == null) return null;
      final photo = await _read(path);
      if (photo != null) {
        await _places.remember(
          householdId: householdId,
          childId: childId,
          date: date,
          signature: signature,
          path: path,
        );
      }
      return photo;
    } on Exception catch (error) {
      AppLog.failure('lunch photo', code: 'unavailable', error: error);
      return null;
    }
  }

  /// Null when the remembered picture can no longer be read — a lost grant,
  /// a removed file — so the Function is asked as if it were never kept.
  Future<Uint8List?> _readKnown(String path) async {
    try {
      return await _read(path);
    } on Exception {
      return null;
    }
  }

  Future<String?> _pathOf(
    String householdId,
    String childId,
    CalendarDate date,
  ) async {
    final callable = _functions.httpsCallable(
      'lunchPhoto',
      options: HttpsCallableOptions(timeout: _timeout),
    );
    for (var attempt = 0; attempt < _pendingTries; attempt++) {
      final result = await callable.call<Object?>({
        'householdId': householdId,
        'childId': childId,
        'date': date.iso,
      });
      final data = result.data;
      if (data is Map && data['status'] == 'ready' && data['path'] is String) {
        return data['path'] as String;
      }
      await Future<void>.delayed(_pendingWait);
    }
    return null;
  }

  Future<Uint8List?> _read(String path) =>
      _kept.read(path, orFetch: () => _storage.ref(path).getData(_largest));
}
