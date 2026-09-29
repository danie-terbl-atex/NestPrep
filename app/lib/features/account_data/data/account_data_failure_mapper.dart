import 'package:cloud_functions/cloud_functions.dart';

import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/app_log.dart';
import '../../household/data/household_failure_mapper.dart';

/// Translates an account-data callable's refusal into an `AppFailure`
/// (accounts ADR-0006). Its own reasons become an `AccountDataFailure`;
/// "sign in first" and "a kid sign-in cannot do that" are the household's
/// words, so they go through the household's mapper — one fallback for a gRPC
/// code, not two (`ENG-01`, `BE-04`).
AppFailure failureFromAccountDataCallable(FirebaseFunctionsException error) {
  final details = error.details;
  final reason = details is Map ? details['reason'] : null;
  final problem = AccountDataProblem.values
      .where((value) => value.name == reason)
      .firstOrNull;
  if (problem == null) return failureFromCallable(error);
  AppLog.failure('account data callable', code: error.code, error: error);
  return AccountDataFailure(problem);
}
