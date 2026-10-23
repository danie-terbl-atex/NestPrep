import 'package:cloud_functions/cloud_functions.dart';

import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/app_log.dart';

/// Translates a Pick n Pay callable's refusal into an `AppFailure` by the
/// `reason` the Function put in its details (`BE-04`), falling back to the
/// code when there is no reason this build knows.
AppFailure failureFromPnpCallable(FirebaseFunctionsException error) {
  AppLog.failure('pnp callable', code: error.code, error: error);
  final details = error.details;
  final reason = details is Map ? details['reason'] : null;
  final problem = switch (reason) {
    'pnp-switched-off' => PnpProblem.featureOff,
    'pnp-no-pending-link' => PnpProblem.noPendingLink,
    'pnp-link-refused' => PnpProblem.linkRefused,
    'pnp-link-expired' => PnpProblem.linkExpired,
    'pnp-down' => PnpProblem.pnpDown,
    'pnp-no-delivery-address' => PnpProblem.noDeliveryAddress,
    _ => null,
  };
  if (problem != null) return PnpFailure(problem);
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
