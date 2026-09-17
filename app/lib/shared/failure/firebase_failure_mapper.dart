import 'package:firebase_core/firebase_core.dart';

import '../log/app_log.dart';
import 'app_failure.dart';

/// Translates a Firebase SDK error into an `AppFailure` at the repository edge.
/// Codes are the Firestore client's gRPC-derived codes.
AppFailure failureFromFirebase(Object error) {
  if (error is AppFailure) return error;
  if (error is! FirebaseException) return UnknownFailure(error);
  AppLog.failure('firestore', code: error.code, error: error);
  return switch (error.code) {
    'permission-denied' => const PermissionDeniedFailure(),
    'unavailable' || 'deadline-exceeded' => const UnavailableFailure(),
    'not-found' => const NotFoundFailure(),
    _ => UnknownFailure(error),
  };
}
