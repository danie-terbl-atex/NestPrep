import 'package:cloud_functions/cloud_functions.dart';

import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/app_log.dart';
import '../model/premium_feature.dart';

/// Translates a subscriptions callable's refusal — `getSubscriptionOffer`,
/// `verifyPurchase`, `setChildProfile` — into an `AppFailure`, by the
/// `reason` the Function put in its details (`BE-04`, subscriptions
/// ADR-0001). The free tier's limit carries the feature it was reached on,
/// so the paywall can open on it.
AppFailure failureFromSubscriptionCallable(FirebaseFunctionsException error) {
  AppLog.failure('subscriptions callable', code: error.code, error: error);
  final details = error.details;
  final reason = details is Map ? details['reason'] : null;
  if (reason == 'premiumRequired') {
    final feature = details is Map ? details['feature'] : null;
    return PremiumRequiredFailure(
      PremiumFeature.values.where((f) => f.name == feature).firstOrNull ??
          PremiumFeature.direct,
    );
  }
  if (reason is String) {
    final problem = SubscriptionProblem.values
        .where((value) => value.name == reason)
        .firstOrNull;
    if (problem != null) return SubscriptionFailure(problem);
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
