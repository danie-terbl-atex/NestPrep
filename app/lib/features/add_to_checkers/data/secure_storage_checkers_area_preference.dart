import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../shared/log/app_log.dart';
import '../model/checkers_area.dart';
import 'checkers_area_preference.dart';

/// The Checkers area in `flutter_secure_storage` — the app's one key-value
/// store on the phone already, so this adds no dependency. Nothing here is
/// secret; a city name does not need the Keychain, it only needs a home.
final class SecureStorageCheckersAreaPreference
    implements CheckersAreaPreference {
  SecureStorageCheckersAreaPreference({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _prefix = 'nestprep.checkersArea.';

  final FlutterSecureStorage _storage;

  @override
  Future<CheckersArea?> read(String householdId) async {
    try {
      final code = await _storage.read(key: '$_prefix$householdId');
      return code == null ? null : CheckersArea.fromCode(code);
    } on PlatformException catch (error) {
      // An unreadable preference is the same as none: the matches fall back
      // to the default city, and choosing again writes a fresh one.
      AppLog.failure('checkers area read', code: error.code, error: error);
      return null;
    }
  }

  @override
  Future<void> write(String householdId, CheckersArea area) async {
    try {
      await _storage.write(key: '$_prefix$householdId', value: area.code);
    } on PlatformException catch (error) {
      // The choice still applies for this run — the controller holds it —
      // it just will not be remembered next time.
      AppLog.failure('checkers area write', code: error.code, error: error);
    }
  }
}
