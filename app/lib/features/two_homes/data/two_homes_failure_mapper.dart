import 'package:cloud_functions/cloud_functions.dart';

import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/app_log.dart';

/// Translates a co-parenting callable's refusal into an `AppFailure`, by the
/// `reason` the Function put in its details (`BE-04`, household ADR-0004).
/// Membership refusals keep the household's words, as the nanny hub's do.
AppFailure failureFromTwoHomesCallable(FirebaseFunctionsException error) {
  AppLog.failure('two homes callable', code: error.code, error: error);
  final details = error.details;
  final reason = details is Map ? details['reason'] : null;
  if (reason is String) {
    final problem = CoParentProblem.values
        .where((value) => value.name == reason)
        .firstOrNull;
    if (problem != null) return CoParentFailure(problem);

    final householdProblem = HouseholdProblem.values
        .where((value) => value.name == reason)
        .firstOrNull;
    if (householdProblem != null) return HouseholdFailure(householdProblem);
  }
  return switch (error.code) {
    'unauthenticated' => const HouseholdFailure(HouseholdProblem.notSignedIn),
    'permission-denied' => const PermissionDeniedFailure(),
    'unavailable' || 'deadline-exceeded' => const UnavailableFailure(),
    'not-found' => const NotFoundFailure(),
    _ => UnknownFailure(error),
  };
}
