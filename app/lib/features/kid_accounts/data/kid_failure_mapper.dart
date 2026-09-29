import 'package:cloud_functions/cloud_functions.dart';

import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/app_log.dart';
import '../../household/data/household_failure_mapper.dart';

/// Translates a kid sign-in callable's refusal into an `AppFailure`
/// (accounts ADR-0003).
///
/// Its own reasons become a `KidSignInFailure`; everything else — "only an
/// admin can do that", "that person is no longer in the household", "a kid
/// sign-in cannot do that" — is the household's vocabulary, and goes through
/// the household's mapper so there is one fallback for a gRPC code rather than
/// two (`ENG-01`, `BE-04`).
AppFailure failureFromKidCallable(FirebaseFunctionsException error) {
  final details = error.details;
  final reason = details is Map ? details['reason'] : null;
  final problem = KidSignInProblem.values
      .where((value) => value.name == reason)
      .firstOrNull;
  if (problem == null) return failureFromCallable(error);
  AppLog.failure('kid sign-in callable', code: error.code, error: error);
  return KidSignInFailure(problem);
}
