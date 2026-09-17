import 'package:cloud_functions/cloud_functions.dart';

import '../model/member_role.dart';
import 'household_directory.dart';
import 'household_failure_mapper.dart';

final class CallableHouseholdDirectory implements HouseholdDirectory {
  const CallableHouseholdDirectory(this._functions);

  final FirebaseFunctions _functions;

  @override
  Future<String> createHousehold({
    required String name,
    required String timeZone,
    required String adminDisplayName,
    required String adminColorName,
  }) async {
    final result = await _call('createHousehold', {
      'name': name,
      'timeZone': timeZone,
      'adminDisplayName': adminDisplayName,
      'adminColor': adminColorName,
    });
    return _requireString(result, 'householdId');
  }

  @override
  Future<InviteCode> createInvite({
    required String householdId,
    required String memberId,
  }) async {
    final result = await _call('createInvite', {
      'householdId': householdId,
      'memberId': memberId,
    });
    return InviteCode(
      code: _requireString(result, 'code'),
      expiresAt: DateTime.parse(_requireString(result, 'expiresAt')).toUtc(),
    );
  }

  @override
  Future<String> redeemInvite(String code) async {
    final result = await _call('redeemInvite', {'code': code});
    return _requireString(result, 'householdId');
  }

  @override
  Future<void> leaveHousehold(String householdId) async {
    await _call('leaveHousehold', {'householdId': householdId});
  }

  @override
  Future<void> removeMember({
    required String householdId,
    required String memberId,
  }) async {
    await _call('removeMember', {
      'householdId': householdId,
      'memberId': memberId,
    });
  }

  @override
  Future<void> setMemberRole({
    required String householdId,
    required String memberId,
    required MemberRole role,
  }) async {
    await _call('setMemberRole', {
      'householdId': householdId,
      'memberId': memberId,
      'role': role.name,
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
      throw failureFromCallable(error);
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
