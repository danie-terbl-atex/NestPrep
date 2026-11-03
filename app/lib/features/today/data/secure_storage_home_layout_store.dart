import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../shared/log/app_log.dart';
import '../model/home_layout.dart';
import 'home_layout_store.dart';

final class SecureStorageHomeLayoutStore implements HomeLayoutStore {
  SecureStorageHomeLayoutStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'nestprep.homeLayout';

  final FlutterSecureStorage _storage;

  @override
  Future<HomeLayout?> read() async {
    try {
      final stored = await _storage.read(key: _key);
      return stored == null ? null : HomeLayout.fromName(stored);
    } on PlatformException catch (error) {
      AppLog.failure('home layout read', code: error.code, error: error);
      return null;
    }
  }

  @override
  Future<void> write(HomeLayout layout) async {
    try {
      await _storage.write(key: _key, value: layout.name);
    } on PlatformException catch (error) {
      AppLog.failure('home layout write', code: error.code, error: error);
    }
  }
}
