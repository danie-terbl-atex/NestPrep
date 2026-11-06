import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../shared/log/app_log.dart';
import '../../../shared/time/calendar_date.dart';
import 'digest_prompt_store.dart';

final class SecureStorageDigestPromptStore implements DigestPromptStore {
  SecureStorageDigestPromptStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static String _key(String householdId, String memberId) =>
      'nestprep.digestOffered.$householdId.$memberId';

  @override
  Future<CalendarDate?> lastOffered(String householdId, String memberId) async {
    try {
      final stored = await _storage.read(key: _key(householdId, memberId));
      return stored == null ? null : CalendarDate.parse(stored);
    } on PlatformException catch (error) {
      AppLog.failure('digest offered read', code: error.code, error: error);
      return null;
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> markOffered(
    String householdId,
    String memberId,
    CalendarDate day,
  ) async {
    try {
      await _storage.write(key: _key(householdId, memberId), value: day.iso);
    } on PlatformException catch (error) {
      AppLog.failure('digest offered write', code: error.code, error: error);
    }
  }
}
