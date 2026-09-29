import 'package:cloud_functions/cloud_functions.dart';

import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/app_log.dart';

/// Translates a nanny-hub callable's refusal into an `AppFailure`, by the
/// `reason` the Function put in its details (`BE-04`, nanny-hub ADR-0002).
/// Membership refusals keep the household's words, as documents' do.
AppFailure failureFromNannyCallable(FirebaseFunctionsException error) {
  AppLog.failure('nanny hub callable', code: error.code, error: error);
  final details = error.details;
  final reason = details is Map ? details['reason'] : null;
  if (reason is String) {
    final nannyProblem = NannyHubProblem.values
        .where((value) => value.name == reason)
        .firstOrNull;
    if (nannyProblem != null) return NannyHubFailure(nannyProblem);

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
