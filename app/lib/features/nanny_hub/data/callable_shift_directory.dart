import 'package:cloud_functions/cloud_functions.dart';

import 'nanny_failure_mapper.dart';
import 'shift_directory.dart';

final class CallableShiftDirectory implements ShiftDirectory {
  const CallableShiftDirectory(this._functions);

  final FirebaseFunctions _functions;

  @override
  Future<void> endShift({
    required String householdId,
    required String shiftId,
    String? closingNote,
  }) async {
    try {
      await _functions.httpsCallable('endNannyShift').call<Object?>({
        'householdId': householdId,
        'shiftId': shiftId,
        'closingNote': closingNote,
      });
    } on FirebaseFunctionsException catch (error) {
      throw failureFromNannyCallable(error);
    }
  }

  @override
  Future<void> setCarerShiftOnly({
    required String householdId,
    required String memberId,
    required bool isShiftOnly,
  }) async {
    try {
      await _functions.httpsCallable('setCarerShiftOnly').call<Object?>({
        'householdId': householdId,
        'memberId': memberId,
        'shiftOnly': isShiftOnly,
      });
    } on FirebaseFunctionsException catch (error) {
      throw failureFromNannyCallable(error);
    }
  }
}
