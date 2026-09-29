import 'package:cloud_functions/cloud_functions.dart';

import '../../household/data/household_failure_mapper.dart';
import 'activity_recorder.dart';

final class CallableActivityRecorder implements ActivityRecorder {
  const CallableActivityRecorder(this._functions);

  /// The callable's name in `functions/src/index.ts`.
  static const callableName = 'recordActivity';

  final FirebaseFunctions _functions;

  @override
  Future<void> recordActivity(String householdId) async {
    try {
      await _functions.httpsCallable(callableName).call<Object?>({
        'householdId': householdId,
      });
    } on FirebaseFunctionsException catch (error) {
      // The refusals are the household ones (`notAMember`, `notSignedIn`), so
      // the household mapper already knows them (`ENG-01`).
      throw failureFromCallable(error);
    }
  }
}
