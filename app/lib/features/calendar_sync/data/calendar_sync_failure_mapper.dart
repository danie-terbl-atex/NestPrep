import 'package:cloud_functions/cloud_functions.dart';

import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/app_log.dart';

/// Translates a calendar sync callable's refusal into an `AppFailure`, by the
/// `reason` the Function put in its details (`BE-04`, calendar ADR-0003).
/// Membership refusals keep the household's words, as documents' do.
AppFailure failureFromCalendarSyncCallable(FirebaseFunctionsException error) {
  AppLog.failure('calendar sync callable', code: error.code, error: error);
  final details = error.details;
  final reason = details is Map ? details['reason'] : null;
  if (reason is String) {
    final syncProblem = CalendarSyncProblem.values
        .where((value) => value.name == reason)
        .firstOrNull;
    if (syncProblem != null) return CalendarSyncFailure(syncProblem);

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
