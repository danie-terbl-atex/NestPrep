import 'package:cloud_functions/cloud_functions.dart';

import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/app_log.dart';
import '../../subscriptions/model/premium_feature.dart';

/// Translates `planMyWeek`'s refusal into an `AppFailure`, by the `reason` in
/// its details (`BE-04`): the plan's own reasons, the shared AI ones
/// (foundation ADR-0015), subscriptions' premium refusal, and the household's
/// membership reasons, which the Function reuses because that is what they
/// are about.
AppFailure failureFromPlanWeekCallable(FirebaseFunctionsException error) {
  AppLog.failure('plan my week callable', code: error.code, error: error);
  final details = error.details;
  final reason = details is Map ? details['reason'] : null;
  if (reason == 'premiumRequired') {
    return const PremiumRequiredFailure(PremiumFeature.aiPlanning);
  }
  if (reason is String) {
    if (_named(PlanWeekProblem.values, reason) case final problem?) {
      return PlanWeekFailure(problem);
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
    // The phone's own wait ran out: as far as the person is concerned, the
    // model did not answer.
    'deadline-exceeded' => const AiFailure(AiProblem.aiUnavailable),
    'unavailable' => const UnavailableFailure(),
    _ => UnknownFailure(error),
  };
}

T? _named<T extends Enum>(List<T> values, String name) =>
    values.where((value) => value.name == name).firstOrNull;
