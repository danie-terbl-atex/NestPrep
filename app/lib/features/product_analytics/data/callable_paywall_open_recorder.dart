import 'package:cloud_functions/cloud_functions.dart';

import '../../household/data/household_failure_mapper.dart';
import '../../subscriptions/model/premium_feature.dart';
import 'paywall_open_recorder.dart';

final class CallablePaywallOpenRecorder implements PaywallOpenRecorder {
  const CallablePaywallOpenRecorder(this._functions);

  /// The callable's name in `functions/src/index.ts`.
  static const callableName = 'recordPaywallOpened';

  final FirebaseFunctions _functions;

  @override
  Future<void> recordPaywallOpened({
    required String householdId,
    required PremiumFeature trigger,
  }) async {
    try {
      await _functions.httpsCallable(callableName).call<Object?>({
        'householdId': householdId,
        'trigger': trigger.name,
      });
    } on FirebaseFunctionsException catch (error) {
      // The refusals are the household ones, like `recordActivity`'s (`ENG-01`).
      throw failureFromCallable(error);
    }
  }
}
