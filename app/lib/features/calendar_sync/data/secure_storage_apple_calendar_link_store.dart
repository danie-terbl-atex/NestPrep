import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../shared/log/app_log.dart';
import '../model/apple_calendar.dart';
import 'apple_calendar_link_store.dart';

final class SecureStorageAppleCalendarLinkStore
    implements AppleCalendarLinkStore {
  SecureStorageAppleCalendarLinkStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static String keyFor(String uid, String householdId) =>
      'nestprep.appleCalendar.$uid.$householdId';

  @override
  Future<AppleCalendarLink?> read(String uid, String householdId) async {
    try {
      final stored = await _storage.read(key: keyFor(uid, householdId));
      return stored == null
          ? null
          : AppleCalendarLink.fromJson(jsonDecode(stored));
    } on PlatformException catch (error) {
      AppLog.failure(
        'apple calendar link read',
        code: error.code,
        error: error,
      );
      return null;
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> write(
    String uid,
    String householdId,
    AppleCalendarLink link,
  ) async {
    try {
      await _storage.write(
        key: keyFor(uid, householdId),
        value: jsonEncode(link.toJson()),
      );
    } on PlatformException catch (error) {
      AppLog.failure(
        'apple calendar link write',
        code: error.code,
        error: error,
      );
    }
  }

  @override
  Future<void> clear(String uid, String householdId) async {
    try {
      await _storage.delete(key: keyFor(uid, householdId));
    } on PlatformException catch (error) {
      AppLog.failure(
        'apple calendar link clear',
        code: error.code,
        error: error,
      );
    }
  }
}
