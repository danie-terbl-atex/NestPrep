import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/app_log.dart';

/// Translates the two sign-in SDKs' errors into one `SignInFailure` at the
/// gateway edge, so nothing above it knows either SDK exists and no SDK message
/// can reach a screen (`FE-09`, `BE-04`).
AppFailure failureFromGoogleSignIn(GoogleSignInException error) {
  AppLog.failure('google sign-in', code: error.code.name, error: error);
  return SignInFailure(switch (error.code) {
    GoogleSignInExceptionCode.canceled => SignInProblem.cancelled,
    GoogleSignInExceptionCode.interrupted ||
    GoogleSignInExceptionCode.uiUnavailable => SignInProblem.networkUnavailable,
    GoogleSignInExceptionCode.clientConfigurationError ||
    GoogleSignInExceptionCode.providerConfigurationError =>
      SignInProblem.notConfigured,
    GoogleSignInExceptionCode.userMismatch ||
    GoogleSignInExceptionCode.unknownError => SignInProblem.unknown,
  });
}

AppFailure failureFromFirebaseAuth(FirebaseAuthException error) {
  AppLog.failure('firebase sign-in', code: error.code, error: error);
  return SignInFailure(switch (error.code) {
    'network-request-failed' => SignInProblem.networkUnavailable,
    'user-disabled' => SignInProblem.accountDisabled,
    'wrong-password' ||
    'user-not-found' ||
    'invalid-credential' ||
    'invalid-email' => SignInProblem.wrongCredentials,
    'operation-not-allowed' ||
    'invalid-api-key' ||
    'app-not-authorized' => SignInProblem.notConfigured,
    _ => SignInProblem.unknown,
  });
}
