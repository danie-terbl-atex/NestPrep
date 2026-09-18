import 'package:cloud_functions/cloud_functions.dart';

import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/app_log.dart';

/// Translates a documents callable's refusal into an `AppFailure`.
///
/// Same contract as the household one (`BE-04`): the Function puts its own
/// `reason` in the error's details, so the client never reads a message or
/// guesses from a gRPC code. Two of those reasons are about *household
/// membership* rather than about documents — `notAMember`, `notAnAdmin` — and
/// they map to the copy the app already has for them rather than to a second
/// way of saying the same thing (documents ADR-0001).
AppFailure failureFromDocumentCallable(FirebaseFunctionsException error) {
  AppLog.failure('documents callable', code: error.code, error: error);
  final details = error.details;
  final reason = details is Map ? details['reason'] : null;
  if (reason is String) {
    final documentProblem = DocumentProblem.values
        .where((value) => value.name == reason)
        .firstOrNull;
    if (documentProblem != null) return DocumentFailure(documentProblem);

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
