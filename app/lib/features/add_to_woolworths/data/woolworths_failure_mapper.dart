import 'package:cloud_functions/cloud_functions.dart';

import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/app_log.dart';

/// Translates a Woolworths callable's refusal into an `AppFailure` by the
/// `reason` the Function put in its details (`BE-04`), falling back to the
/// code when there is no reason this build knows.
AppFailure failureFromWoolworthsCallable(FirebaseFunctionsException error) {
  AppLog.failure('woolworths callable', code: error.code, error: error);
  final details = error.details;
  final reason = details is Map ? details['reason'] : null;
  final problem = switch (reason) {
    'woolworths-off' ||
    'woolworths-switched-off' => WoolworthsProblem.featureOff,
    'woolworths-not-linked' => WoolworthsProblem.notLinked,
    'woolworths-link-expired' => WoolworthsProblem.linkExpired,
    'woolworths-link-rejected' => WoolworthsProblem.linkRejected,
    'woolworths-unavailable' => WoolworthsProblem.woolworthsDown,
    'woolworths-rejected' => WoolworthsProblem.cartRefused,
    'woolworths-no-delivery-address' => WoolworthsProblem.noDeliveryAddress,
    _ => null,
  };
  if (problem != null) return WoolworthsFailure(problem);
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
    'unavailable' || 'deadline-exceeded' => const UnavailableFailure(),
    'not-found' => const NotFoundFailure(),
    _ => UnknownFailure(error),
  };
}
