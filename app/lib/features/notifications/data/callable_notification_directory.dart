import 'package:cloud_functions/cloud_functions.dart';

import '../../../shared/failure/firebase_failure_mapper.dart';
import 'notification_directory.dart';

final class CallableNotificationDirectory implements NotificationDirectory {
  const CallableNotificationDirectory(this._functions);

  final FirebaseFunctions _functions;

  @override
  Future<TestPushOutcome> sendTestNotification(String householdId) async {
    try {
      final result = await _functions
          .httpsCallable('sendTestNotification')
          .call<Object?>({'householdId': householdId});
      final data = result.data;
      return TestPushOutcome.fromName(
        data is Map<Object?, Object?> ? data['outcome'] : null,
      );
    } on FirebaseFunctionsException catch (error) {
      throw failureFromFirebase(error);
    }
  }
}
