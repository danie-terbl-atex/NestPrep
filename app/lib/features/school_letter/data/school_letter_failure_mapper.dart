import 'package:cloud_functions/cloud_functions.dart';

import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/app_log.dart';

/// Translates `readSchoolLetter`'s refusal into an `AppFailure`, by the
/// `reason` in its details (`BE-04`): the letter's own reasons, the shared AI
/// ones (foundation ADR-0015), and calendar sync's membership and grant
/// reasons, which the Function reuses because that is what they are about.
AppFailure failureFromLetterCallable(FirebaseFunctionsException error) {
  AppLog.failure('school letter callable', code: error.code, error: error);
  final details = error.details;
  final reason = details is Map ? details['reason'] : null;
  if (reason is String) {
    if (_named(SchoolLetterProblem.values, reason) case final problem?) {
      return SchoolLetterFailure(problem);
    }
    if (_named(AiProblem.values, reason) case final problem?) {
      return AiFailure(problem);
    }
    if (_named(CalendarSyncProblem.values, reason) case final problem?) {
      return CalendarSyncFailure(problem);
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
