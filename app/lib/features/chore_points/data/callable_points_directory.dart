import 'package:cloud_functions/cloud_functions.dart';

import 'points_directory.dart';
import 'points_failure_mapper.dart';

final class CallablePointsDirectory implements PointsDirectory {
  const CallablePointsDirectory(this._functions);

  final FirebaseFunctions _functions;

  @override
  Future<void> reviewChore({
    required String householdId,
    required String completionId,
    required ChoreReview decision,
  }) => _call('reviewChore', {
    'householdId': householdId,
    'completionId': completionId,
    'decision': decision.name,
  });

  @override
  Future<void> settleReward({
    required String householdId,
    required String requestId,
    required RewardSettlement decision,
  }) => _call('settleReward', {
    'householdId': householdId,
    'requestId': requestId,
    'decision': decision.name,
  });

  Future<void> _call(String name, Map<String, Object?> payload) async {
    try {
      await _functions.httpsCallable(name).call<Object?>(payload);
    } on FirebaseFunctionsException catch (error) {
      throw failureFromPointsCallable(error);
    }
  }
}
