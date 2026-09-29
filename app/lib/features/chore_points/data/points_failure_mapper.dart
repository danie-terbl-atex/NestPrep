import 'package:cloud_functions/cloud_functions.dart';

import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/app_log.dart';
import '../../household/data/household_failure_mapper.dart';

/// A chore-points refusal becomes a `PointsFailure`; anything else is the
/// household's vocabulary and goes through its mapper, so there is one
/// fallback for a gRPC code rather than two (`ENG-01`, `BE-04`).
AppFailure failureFromPointsCallable(FirebaseFunctionsException error) {
  final details = error.details;
  final reason = details is Map ? details['reason'] : null;
  final problem = PointsProblem.values
      .where((value) => value.name == reason)
      .firstOrNull;
  if (problem == null) return failureFromCallable(error);
  AppLog.failure('chore points callable', code: error.code, error: error);
  return PointsFailure(problem);
}
