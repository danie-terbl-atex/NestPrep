import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../shared/log/app_log.dart';
import '../model/lunch_variety.dart';
import 'lunch_variety_store.dart';

/// The variety choice in `flutter_secure_storage`, the app's one key-value
/// store on the phone, as the packing choice is. Nothing here is secret.
final class SecureStorageLunchVarietyStore implements LunchVarietyStore {
  SecureStorageLunchVarietyStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _prefix = 'nestprep.lunchVariety.';

  final FlutterSecureStorage _storage;

  @override
  Future<LunchVariety?> read(String householdId) async {
    try {
      final stored = await _storage.read(key: '$_prefix$householdId');
      return stored == null ? null : fromStored(stored);
    } on PlatformException catch (error) {
      AppLog.failure('lunch variety read', code: error.code, error: error);
      return null;
    }
  }

  @override
  Future<void> write(String householdId, LunchVariety variety) async {
    try {
      await _storage.write(
        key: '$_prefix$householdId',
        value: toStored(variety),
      );
    } on PlatformException catch (error) {
      AppLog.failure('lunch variety write', code: error.code, error: error);
    }
  }

  static String toStored(LunchVariety variety) => jsonEncode(variety.names);

  static LunchVariety? fromStored(String stored) {
    try {
      return switch (jsonDecode(stored)) {
        final List<Object?> names => LunchVariety.fromNames(names),
        _ => null,
      };
    } on FormatException {
      return null;
    }
  }
}
