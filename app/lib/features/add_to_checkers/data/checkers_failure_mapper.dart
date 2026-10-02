import 'package:cloud_functions/cloud_functions.dart';

import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/app_log.dart';

/// Translates a Checkers callable's refusal into an `AppFailure` by the
/// `reason` the Function put in its details (`BE-04`), falling back to the
/// code when there is no reason this build knows.
AppFailure failureFromCheckersCallable(FirebaseFunctionsException error) {
  AppLog.failure('checkers callable', code: error.code, error: error);
  final details = error.details;
  final reason = details is Map ? details['reason'] : null;
  final problem = switch (reason) {
    'bad-mobile' => CheckersProblem.badMobile,
    'otp-rate-limited' => CheckersProblem.otpRateLimited,
    'checkers-down' => CheckersProblem.checkersDown,
    'no-pending-otp' => CheckersProblem.noPendingOtp,
    'wrong-code' => CheckersProblem.wrongCode,
    'checkers-link-expired' => CheckersProblem.linkExpired,
    'no-checkers-store' => CheckersProblem.noStoreForAccount,
    'checkers-switched-off' => CheckersProblem.featureOff,
    _ => null,
  };
  if (problem != null) return CheckersFailure(problem);
  final householdProblem = switch (reason) {
    'not-a-member' => HouseholdProblem.notAMember,
    'notSignedIn' => HouseholdProblem.notSignedIn,
    'kidAccount' => HouseholdProblem.kidAccount,
    'badRequest' => HouseholdProblem.badRequest,
    _ => null,
  };
  if (householdProblem != null) return HouseholdFailure(householdProblem);
  return switch (error.code) {
    'unauthenticated' => const HouseholdFailure(HouseholdProblem.notSignedIn),
    'permission-denied' => const PermissionDeniedFailure(),
    'resource-exhausted' => const CheckersFailure(
      CheckersProblem.otpRateLimited,
    ),
    'unavailable' || 'deadline-exceeded' => const UnavailableFailure(),
    'not-found' => const NotFoundFailure(),
    _ => UnknownFailure(error),
  };
}
