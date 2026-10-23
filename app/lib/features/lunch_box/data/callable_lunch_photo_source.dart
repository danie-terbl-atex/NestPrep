import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../shared/log/app_log.dart';
import '../../../shared/photos/kept_photo_files.dart';
import '../../../shared/time/calendar_date.dart';
import 'lunch_photo_source.dart';

/// `lunchPhoto` (lunch-box ADR-0015): the Function finds or makes the photo
/// and names where it is in Storage; the bytes are kept on the phone by that
/// name, which never changes for a combination, so each is fetched once.
final class CallableLunchPhotoSource implements LunchPhotoSource {
  CallableLunchPhotoSource(this._functions, this._storage);

  final FirebaseFunctions _functions;
  final FirebaseStorage _storage;
  final _requests = <String, Future<Uint8List?>>{};
  final _kept = KeptPhotoFiles('lunch_photos');

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
      final photo = await _fetch(householdId, childId, date);
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
  ) async {
    try {
      final path = await _pathOf(householdId, childId, date);
      return path == null ? null : await _read(path);
    } on Exception catch (error) {
      AppLog.failure('lunch photo', code: 'unavailable', error: error);
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
