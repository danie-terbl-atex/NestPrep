import 'package:cloud_functions/cloud_functions.dart';

import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/app_log.dart';

/// Translates a referrals callable's refusal into an `AppFailure`, by the
/// `reason` the Function put in its details (`BE-04`, subscriptions
/// ADR-0002). A malformed code the edge refused is `referralCodeNotFound` to a
/// person: from where they stand, it is not a code we know.
AppFailure failureFromReferralCallable(FirebaseFunctionsException error) {
  AppLog.failure('referrals callable', code: error.code, error: error);
  final details = error.details;
  final reason = details is Map ? details['reason'] : null;
  if (reason == 'badRequest') {
    return const ReferralFailure(ReferralProblem.referralCodeNotFound);
  }
  if (reason is String) {
    final problem = ReferralProblem.values
        .where((value) => value.name == reason)
        .firstOrNull;
    if (problem != null) return ReferralFailure(problem);
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
