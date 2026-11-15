import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../shared/log/app_log.dart';
import '../model/appearance.dart';
import 'appearance_store.dart';

/// Kept on the phone, never in Firestore: a second phone of the same person
/// may well want the other choice.
final class SecureStorageAppearanceStore implements AppearanceStore {
  SecureStorageAppearanceStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'nestprep.appearance';

  final FlutterSecureStorage _storage;

  @override
  Future<Appearance?> read() async {
    try {
      final stored = await _storage.read(key: _key);
      return stored == null ? null : Appearance.fromName(stored);
    } on PlatformException catch (error) {
      AppLog.failure('appearance read', code: error.code, error: error);
      return null;
    }
  }

  @override
  Future<void> write(Appearance appearance) async {
    try {
      await _storage.write(key: _key, value: appearance.name);
    } on PlatformException catch (error) {
      AppLog.failure('appearance write', code: error.code, error: error);
    }
  }
}
