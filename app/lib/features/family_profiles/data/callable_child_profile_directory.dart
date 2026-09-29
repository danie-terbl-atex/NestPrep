import 'package:cloud_functions/cloud_functions.dart';

import '../../subscriptions/data/subscription_failure_mapper.dart';
import 'child_profile_directory.dart';

/// `setChildProfile` over the Functions SDK. Its refusals are the
/// subscriptions ones — the free tier's limit among them — so it maps them
/// the same way (`BE-04`).
final class CallableChildProfileDirectory implements ChildProfileDirectory {
  const CallableChildProfileDirectory(this._functions);

  final FirebaseFunctions _functions;

  static const callableName = 'setChildProfile';

  @override
  Future<void> setIsChild({
    required String householdId,
    required String memberId,
    required bool isChild,
    int? guardianConsentVersion,
  }) async {
    try {
      await _functions.httpsCallable(callableName).call<Object?>({
        'householdId': householdId,
        'memberId': memberId,
        'isChild': isChild,
        if (guardianConsentVersion != null)
          'guardianConsent': {'version': guardianConsentVersion},
      });
    } on FirebaseFunctionsException catch (error) {
      throw failureFromSubscriptionCallable(error);
    }
  }
}
