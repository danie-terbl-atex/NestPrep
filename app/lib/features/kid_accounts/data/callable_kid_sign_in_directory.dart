import 'package:cloud_functions/cloud_functions.dart';

import '../model/kid_pairing.dart';
import 'kid_failure_mapper.dart';
import 'kid_sign_in_directory.dart';

final class CallableKidSignInDirectory implements KidSignInDirectory {
  const CallableKidSignInDirectory(this._functions);

  final FirebaseFunctions _functions;

  @override
  Future<KidPairing> createPairing({
    required String householdId,
    required String memberId,
    required String label,
  }) async {
    final result = await _call('createKidPairing', {
      'householdId': householdId,
      'memberId': memberId,
      'label': label,
    });
    return KidPairing(
      code: _requireString(result, 'code'),
      memberId: memberId,
      expiresAt: DateTime.parse(_requireString(result, 'expiresAt')).toUtc(),
    );
  }

  @override
  Future<void> cancelPairing({
    required String householdId,
    required String code,
  }) async {
    await _call('cancelKidPairing', {'householdId': householdId, 'code': code});
  }

  @override
  Future<String> redeem(String code) async {
    final result = await _call('redeemKidPairing', {'code': code});
    return _requireString(result, 'token');
  }

  @override
  Future<void> revokeDevice({
    required String householdId,
    required String deviceUid,
  }) async {
    await _call('revokeKidDevice', {
      'householdId': householdId,
      'deviceUid': deviceUid,
    });
  }

  @override
  Future<void> resetSignIn({
    required String householdId,
    required String memberId,
  }) async {
    await _call('resetKidSignIn', {
      'householdId': householdId,
      'memberId': memberId,
    });
  }

  Future<Map<String, Object?>> _call(
    String name,
    Map<String, Object?> payload,
  ) async {
    try {
      final result = await _functions
          .httpsCallable(name)
          .call<Object?>(payload);
      final data = result.data;
      return data is Map ? Map<String, Object?>.from(data) : const {};
    } on FirebaseFunctionsException catch (error) {
      throw failureFromKidCallable(error);
    }
  }

  /// A field the Function documents that it returns. Its absence is our bug,
  /// not the person's, so it fails loudly rather than defaulting (`ENG-09`).
  String _requireString(Map<String, Object?> data, String key) {
    final value = data[key];
    if (value is String && value.isNotEmpty) return value;
    throw FormatException('$key missing from the callable result', data);
  }
}
