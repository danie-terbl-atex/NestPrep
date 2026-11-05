import 'package:cloud_functions/cloud_functions.dart';

import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/app_log.dart';
import '../../subscriptions/model/premium_feature.dart';

/// `readShoppingList`'s refusal as an `AppFailure`, by the `reason` in its
/// details (`BE-04`): premium, the feature's own reasons, the shared AI ones
/// and the household's.
AppFailure failureFromListScanCallable(FirebaseFunctionsException error) {
  AppLog.failure('list scan callable', code: error.code, error: error);
  final details = error.details;
  final reason = details is Map ? details['reason'] : null;
  if (reason == 'premiumRequired') {
    return const PremiumRequiredFailure(PremiumFeature.listScan);
  }
  if (reason is String) {
    if (_named(ListScanProblem.values, reason) case final problem?) {
      return ListScanFailure(problem);
    }
    if (_named(AiProblem.values, reason) case final problem?) {
      return AiFailure(problem);
    }
    if (_named(HouseholdProblem.values, reason) case final problem?) {
      return HouseholdFailure(problem);
    }
  }
  return switch (error.code) {
    'unauthenticated' => const HouseholdFailure(HouseholdProblem.notSignedIn),
    'permission-denied' => const PermissionDeniedFailure(),
    'deadline-exceeded' => const AiFailure(AiProblem.aiUnavailable),
    'unavailable' => const UnavailableFailure(),
    _ => UnknownFailure(error),
  };
}

T? _named<T extends Enum>(List<T> values, String name) =>
    values.where((value) => value.name == name).firstOrNull;
