import 'package:firebase_core/firebase_core.dart';

import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/app_log.dart';

/// Translates a Cloud Storage error into an `AppFailure` at the store's edge.
///
/// Storage has its own code space — `storage/...` rather than the gRPC codes
/// Firestore reports — so the shared mapper cannot read them, and a code it
/// does not recognise becomes "something went wrong" for a refusal the app
/// knows exactly how to explain (`FE-09`, `BE-04`).
AppFailure failureFromStorage(Object error) {
  if (error is AppFailure) return error;
  if (error is! FirebaseException) return UnknownFailure(error);
  AppLog.failure('storage', code: error.code, error: error);
  return switch (error.code) {
    'storage/unauthorized' ||
    'storage/invalid-argument' => const PermissionDeniedFailure(),
    'storage/canceled' => const DocumentFailure(
      DocumentProblem.uploadCancelled,
    ),
    'storage/object-not-found' ||
    'storage/bucket-not-found' => const NotFoundFailure(),
    'storage/unauthenticated' => const SessionExpiredFailure(),
    'storage/retry-limit-exceeded' ||
    'storage/server-file-wrong-size' => const UnavailableFailure(),
    _ => UnknownFailure(error),
  };
}
