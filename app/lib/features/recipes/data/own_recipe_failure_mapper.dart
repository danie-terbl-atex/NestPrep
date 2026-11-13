import 'package:cloud_functions/cloud_functions.dart';

import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/app_log.dart';
import '../../subscriptions/model/premium_feature.dart';

AppFailure failureFromOwnRecipeCallable(FirebaseFunctionsException error) {
  AppLog.failure('own recipe callable', code: error.code, error: error);
  final details = error.details;
  final reason = details is Map ? details['reason'] : null;
  if (reason == 'premiumRequired') {
    return const PremiumRequiredFailure(PremiumFeature.ownRecipes);
  }
  if (reason is String) {
    if (_named(OwnRecipeProblem.values, reason) case final problem?) {
      return OwnRecipeFailure(problem);
    }
    if (_named(HouseholdProblem.values, reason) case final problem?) {
      return HouseholdFailure(problem);
    }
  }
  return switch (error.code) {
    'unauthenticated' => const HouseholdFailure(HouseholdProblem.notSignedIn),
    'permission-denied' => const PermissionDeniedFailure(),
    'unavailable' || 'deadline-exceeded' => const UnavailableFailure(),
    _ => UnknownFailure(error),
  };
}

T? _named<T extends Enum>(List<T> values, String name) =>
    values.where((value) => value.name == name).firstOrNull;
