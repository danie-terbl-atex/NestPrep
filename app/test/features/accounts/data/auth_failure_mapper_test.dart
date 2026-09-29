import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:nestprep/features/accounts/data/auth_failure_mapper.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

/// Which copy a person sees when sign-in fails (`FE-09`, `BE-04`).
///
/// Two SDKs' errors become one `SignInFailure` at the gateway edge, and nothing
/// above it knows either SDK exists. It had no test, and it is the failure
/// surface of the one feature still blocked — the first thing anybody meets when
/// Auth is finally switched on is this mapping, and a wrong arm means the wrong
/// sentence on screen, or a silent screen where there should be a sentence.
///
/// The Google half is a switch over an enum, so the compiler already refuses an
/// unhandled code. The Firebase half switches over **strings** with a
/// catch-all, so nothing but a test can say whether a given code is mapped or
/// merely swallowed into `unknown` — which is the arm that shows the vaguest
/// copy of all.
void main() {
  SignInProblem fromGoogle(GoogleSignInExceptionCode code) {
    final failure = failureFromGoogleSignIn(GoogleSignInException(code: code));
    return (failure as SignInFailure).problem;
  }

  SignInProblem fromFirebase(String code) {
    final failure = failureFromFirebaseAuth(FirebaseAuthException(code: code));
    return (failure as SignInFailure).problem;
  }

  group('the Google sheet', () {
    test('a closed sheet is cancelled, which says nothing to anybody', () {
      // The one failure that must produce no copy at all: the person chose it.
      expect(
        fromGoogle(GoogleSignInExceptionCode.canceled),
        SignInProblem.cancelled,
      );
    });

    test('interrupted and no UI are both the network', () {
      expect(
        fromGoogle(GoogleSignInExceptionCode.interrupted),
        SignInProblem.networkUnavailable,
      );
      expect(
        fromGoogle(GoogleSignInExceptionCode.uiUnavailable),
        SignInProblem.networkUnavailable,
      );
    });

    test('either configuration error is ours, not the person\'s', () {
      // An unregistered SHA-1 or a provider that was never enabled. Telling
      // somebody to check their password would be a lie, and this is the exact
      // state the project is in until the console steps are done.
      expect(
        fromGoogle(GoogleSignInExceptionCode.clientConfigurationError),
        SignInProblem.notConfigured,
      );
      expect(
        fromGoogle(GoogleSignInExceptionCode.providerConfigurationError),
        SignInProblem.notConfigured,
      );
    });

    test('a mismatch and an unknown error both fall through to unknown', () {
      expect(
        fromGoogle(GoogleSignInExceptionCode.userMismatch),
        SignInProblem.unknown,
      );
      expect(
        fromGoogle(GoogleSignInExceptionCode.unknownError),
        SignInProblem.unknown,
      );
    });

    test('every code the SDK has is mapped', () {
      // The switch is exhaustive, so this cannot fail while it compiles — it is
      // here so that an SDK upgrade adding a code is a compile error somebody
      // reads, rather than a silently widened `unknown`.
      for (final code in GoogleSignInExceptionCode.values) {
        expect(fromGoogle(code), isA<SignInProblem>());
      }
    });
  });

  group('Firebase Auth, where the codes are strings', () {
    test('a failed request is the network', () {
      expect(
        fromFirebase('network-request-failed'),
        SignInProblem.networkUnavailable,
      );
    });

    test('a disabled account says so, because the person cannot fix it', () {
      expect(fromFirebase('user-disabled'), SignInProblem.accountDisabled);
    });

    test('the four credential codes are all wrong-credentials', () {
      // These only arise against the seeded emulator users, where a password is
      // typed. Worth pinning anyway: they are the codes most likely to be
      // renamed by an SDK major.
      for (final code in [
        'wrong-password',
        'user-not-found',
        'invalid-credential',
        'invalid-email',
      ]) {
        expect(
          fromFirebase(code),
          SignInProblem.wrongCredentials,
          reason: code,
        );
      }
    });

    test('the three configuration codes are ours', () {
      for (final code in [
        'operation-not-allowed',
        'invalid-api-key',
        'app-not-authorized',
      ]) {
        expect(fromFirebase(code), SignInProblem.notConfigured, reason: code);
      }
    });

    test('operation-not-allowed is the one the project will actually hit', () {
      // It is what Firebase returns when the Google provider exists but has not
      // been enabled — the exact state of `nestprep-643b7` today. It must read
      // as our configuration problem and never as the person's fault.
      expect(
        fromFirebase('operation-not-allowed'),
        SignInProblem.notConfigured,
      );
    });

    test('anything unrecognised is unknown rather than a guess', () {
      expect(fromFirebase('some-new-code'), SignInProblem.unknown);
      expect(fromFirebase(''), SignInProblem.unknown);
    });

    test('the registration codes each get their own sentence', () {
      // All three are things the person can act on, and `unknown` tells them
      // none of it (accounts ADR-0002).
      expect(
        fromFirebase('email-already-in-use'),
        SignInProblem.emailAlreadyRegistered,
      );
      expect(fromFirebase('weak-password'), SignInProblem.weakPassword);
      expect(fromFirebase('too-many-requests'), SignInProblem.tooManyAttempts);
    });

    test('an address that belongs to the other provider asks to be linked', () {
      // The one refusal that is not the person's fault and not ours: they have
      // an account, under the button they did not press.
      expect(
        fromFirebase('account-exists-with-different-credential'),
        SignInProblem.needsLinking,
      );
      expect(
        fromFirebase('credential-already-in-use'),
        SignInProblem.needsLinking,
      );
    });

    test('a spent reset link reads as bad credentials, not as a mystery', () {
      expect(
        fromFirebase('expired-action-code'),
        SignInProblem.wrongCredentials,
      );
      expect(
        fromFirebase('invalid-action-code'),
        SignInProblem.wrongCredentials,
      );
    });

    test('enumeration protection keeps the three wrong-credential codes apart '
        'from nothing', () {
      // Firebase returns these almost interchangeably once enumeration
      // protection is on, so telling them apart on screen is both impossible
      // and the thing we do not want (accounts ADR-0002).
      for (final code in [
        'wrong-password',
        'user-not-found',
        'invalid-credential',
      ]) {
        expect(
          fromFirebase(code),
          SignInProblem.wrongCredentials,
          reason: code,
        );
      }
    });

    test('a code is matched exactly, not by prefix or case', () {
      // The catch-all makes a near-miss invisible: it produces the vaguest copy
      // there is instead of failing, so these pin the matching itself.
      expect(fromFirebase('user-disabled-permanently'), SignInProblem.unknown);
      expect(fromFirebase('USER-DISABLED'), SignInProblem.unknown);
      expect(fromFirebase(' user-disabled'), SignInProblem.unknown);
    });
  });

  test('both halves produce a SignInFailure and nothing else', () {
    // Anything above the gateway matches on `SignInFailure`; another
    // `AppFailure` subclass would reach a screen with no copy for it.
    expect(
      failureFromGoogleSignIn(
        const GoogleSignInException(code: GoogleSignInExceptionCode.canceled),
      ),
      isA<SignInFailure>(),
    );
    expect(
      failureFromFirebaseAuth(FirebaseAuthException(code: 'user-disabled')),
      isA<SignInFailure>(),
    );
  });
}
