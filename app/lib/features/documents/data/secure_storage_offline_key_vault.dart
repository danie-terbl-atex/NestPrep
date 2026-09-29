import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/app_log.dart';
import 'offline_copy_cipher.dart';
import 'offline_key_vault.dart';

/// The offline-copy keys in `flutter_secure_storage` (documents ADR-0007):
/// the Android Keystore underneath, and on iOS the Keychain with *after
/// first unlock, this device only* — so a key never leaves the phone in a
/// backup or through iCloud.
final class SecureStorageOfflineKeyVault implements OfflineKeyVault {
  SecureStorageOfflineKeyVault({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
            ),
          );

  static const _prefix = 'nestprep.offlineKey.';

  final FlutterSecureStorage _storage;

  @override
  Future<List<int>> keyFor(String uid) => _guard(() async {
    final stored = await _storage.read(key: '$_prefix$uid');
    if (stored != null) return base64Decode(stored);
    final key = OfflineCopyCipher.newKey();
    await _storage.write(key: '$_prefix$uid', value: base64Encode(key));
    return key;
  });

  @override
  Future<Set<String>> accounts() => _guard(() async {
    final all = await _storage.readAll();
    return {
      for (final name in all.keys)
        if (name.startsWith(_prefix)) name.substring(_prefix.length),
    };
  });

  @override
  Future<void> forget(String uid) =>
      _guard(() => _storage.delete(key: '$_prefix$uid'));

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PlatformException catch (error) {
      AppLog.failure('offline key', code: error.code, error: error);
      throw const DocumentFailure(DocumentProblem.offlineStorageUnavailable);
    }
  }
}
