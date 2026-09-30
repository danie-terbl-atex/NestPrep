import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/app_log.dart';

/// Translates the two auth SDKs' errors into one `SignInFailure` at the gateway
/// edge, so nothing above it knows either SDK exists and no SDK message can
/// reach a screen (`FE-09`, `BE-04`).
///
/// Covers signing in, registering and resetting a password, which is why this
/// is no longer named after Google alone (accounts ADR-0002).
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
    // Enumeration protection is on, so Firebase returns these three almost
    // interchangeably and the app must not try to tell them apart.
    'wrong-password' ||
    'user-not-found' ||
    'invalid-credential' ||
    'invalid-email' => SignInProblem.wrongCredentials,
    'email-already-in-use' => SignInProblem.emailAlreadyRegistered,
    'weak-password' => SignInProblem.weakPassword,
    'too-many-requests' => SignInProblem.tooManyAttempts,
    // The address has an account under the other provider. Not an error the
    // person caused, and the screen turns it into an offer to link.
    'account-exists-with-different-credential' ||
    'credential-already-in-use' => SignInProblem.needsLinking,
    // A reset or verification link that has already been used or has aged out.
    'expired-action-code' ||
    'invalid-action-code' => SignInProblem.wrongCredentials,
    'operation-not-allowed' ||
    'invalid-api-key' ||
    'app-not-authorized' => SignInProblem.notConfigured,
    _ => SignInProblem.unknown,
  });
}

/// Whether an auth error means the backend refuses this session for good —
/// signing in again is the only cure (accounts ADR-0008).
///
/// Android does not always give these their own code: a refused refresh token
/// arrives as `internal-error` or `unknown` with the service's reason
/// (`INVALID_REFRESH_TOKEN`) only in the message, so the reason is read there
/// too. A network failure is never one of these.
bool isRejectedSession(FirebaseException error) {
  if (_rejectedSessionCodes.contains(error.code)) return true;
  final message = error.message ?? '';
  return _rejectedSessionReasons.any(message.contains);
}

const _rejectedSessionCodes = {
  'user-token-expired',
  'invalid-user-token',
  'user-not-found',
  'user-disabled',
  'invalid-refresh-token',
  'token-expired',
};

const _rejectedSessionReasons = [
  'INVALID_REFRESH_TOKEN',
  'TOKEN_EXPIRED',
  'USER_NOT_FOUND',
  'USER_DISABLED',
  'INVALID_ID_TOKEN',
];
