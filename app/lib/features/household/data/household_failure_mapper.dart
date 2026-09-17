import 'package:cloud_functions/cloud_functions.dart';

import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/app_log.dart';

/// Translates a callable's refusal into an `AppFailure` at the data edge.
///
/// The Function puts its own `reason` in the error's details precisely so the
/// client never has to read a message or guess from a gRPC code (`BE-04`). A
/// reason this build does not know is a Function newer than the app — show the
/// general apology rather than nothing.
AppFailure failureFromCallable(FirebaseFunctionsException error) {
  AppLog.failure('household callable', code: error.code, error: error);
  final details = error.details;
  final reason = details is Map ? details['reason'] : null;
  if (reason is String) {
    final problem = HouseholdProblem.values
        .where((value) => value.name == reason)
        .firstOrNull;
    if (problem != null) return HouseholdFailure(problem);
    return const HouseholdFailure(HouseholdProblem.unrecognised);
  }
  return switch (error.code) {
    'unauthenticated' => const HouseholdFailure(HouseholdProblem.notSignedIn),
    'permission-denied' => const PermissionDeniedFailure(),
    'unavailable' || 'deadline-exceeded' => const UnavailableFailure(),
    'not-found' => const NotFoundFailure(),
    _ => UnknownFailure(error),
  };
}
