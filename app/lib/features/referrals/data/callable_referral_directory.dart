import 'package:cloud_functions/cloud_functions.dart';

import '../../../shared/failure/app_failure.dart';
import 'referral_directory.dart';
import 'referral_failure_mapper.dart';

/// The referrals callables over the Functions SDK. Each answer is parsed
/// rather than cast (`ENG-09`): an answer of the wrong shape is a Function
/// newer or older than this build, and reads as a failure rather than a crash.
final class CallableReferralDirectory implements ReferralDirectory {
  const CallableReferralDirectory(this._functions);

  static const ensureCallable = 'ensureReferralCode';
  static const redeemCallable = 'redeemReferralCode';

  final FirebaseFunctions _functions;

  @override
  Future<String> ensureCode(String householdId) async {
    final result = await _call(ensureCallable, {'householdId': householdId});
    if (result['code'] case final String code when code.isNotEmpty) {
      return code;
    }
    throw UnknownFailure(StateError('ensureReferralCode answered no code'));
  }

  @override
  Future<DateTime> redeem({
    required String householdId,
    required String code,
  }) async {
    final result = await _call(redeemCallable, {
      'householdId': householdId,
      'code': code,
    });
    final qualifyBy = switch (result['qualifyBy']) {
      final String at => DateTime.tryParse(at),
      _ => null,
    };
    if (qualifyBy == null) {
      throw UnknownFailure(StateError('redeemReferralCode answered no date'));
    }
    return qualifyBy.toUtc();
  }

  Future<Map<Object?, Object?>> _call(
    String name,
    Map<String, Object?> payload,
  ) async {
    try {
      final result = await _functions
          .httpsCallable(name)
          .call<Object?>(payload);
      final data = result.data;
      return data is Map ? data : const {};
    } on FirebaseFunctionsException catch (error) {
      throw failureFromReferralCallable(error);
    }
  }
}
