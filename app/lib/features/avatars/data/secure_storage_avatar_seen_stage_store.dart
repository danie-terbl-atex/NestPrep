import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../shared/log/app_log.dart';
import 'avatar_seen_stage_store.dart';

final class SecureStorageAvatarSeenStageStore implements AvatarSeenStageStore {
  SecureStorageAvatarSeenStageStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static String _key(String householdId, String memberId) =>
      'nestprep.avatarStageSeen.$householdId.$memberId';

  @override
  Future<int?> seen(String householdId, String memberId) async {
    try {
      final stored = await _storage.read(key: _key(householdId, memberId));
      return stored == null ? null : int.tryParse(stored);
    } on PlatformException catch (error) {
      AppLog.failure('avatar stage seen read', code: error.code, error: error);
      return null;
    }
  }

  @override
  Future<void> markSeen(String householdId, String memberId, int stage) async {
    try {
      await _storage.write(key: _key(householdId, memberId), value: '$stage');
    } on PlatformException catch (error) {
      AppLog.failure('avatar stage seen write', code: error.code, error: error);
    }
  }
}
