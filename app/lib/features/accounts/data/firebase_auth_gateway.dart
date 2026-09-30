import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/app_log.dart';
import '../model/auth_user.dart';
import '../model/kid_identity.dart';
import '../model/session_check.dart';
import 'auth_failure_mapper.dart';
import 'auth_gateway.dart';
import 'credential_linking.dart';

final class FirebaseAuthGateway implements AuthGateway {
  FirebaseAuthGateway(
    this._auth, {
    GoogleSignIn? googleSignIn,
    CredentialLinking? linking,
  }) : _google = googleSignIn ?? GoogleSignIn.instance,
       _linking = linking ?? CredentialLinking();

  final FirebaseAuth _auth;
  final GoogleSignIn _google;
  final CredentialLinking _linking;
  bool _googleIsInitialised = false;

  /// The uid whose token this process has already had accepted — by signing in
  /// here, or by a check — so a fresh sign-in is not asked about twice.
  String? _acceptedUid;

  /// How long a session check waits for the backend before calling it
  /// unverified. Generous on purpose: the session controller stops waiting on
  /// it far sooner and only listens for a late refusal, so this bounds that
  /// listening rather than any screen.
  static const _checkTimeout = Duration(seconds: 45);

  @override
  Stream<AuthUser?> authStateChanges() =>
      _auth.authStateChanges().asyncMap(_withKidClaim);

  @override
  String? get pendingLinkEmail => _linking.pendingEmail;

  @override
  Future<SessionCheck> checkSession() async {
    final user = _auth.currentUser;
    // Nobody signed in: the auth stream says so on its own, and there is no
    // token to ask about.
    if (user == null) return SessionCheck.unverified;
    if (user.uid == _acceptedUid) return SessionCheck.accepted;
    try {
      // `true` forces a refresh: a cached ID token can look valid for up to an
      // hour after the refresh token behind it has been revoked.
      await user.getIdToken(true).timeout(_checkTimeout);
      _acceptedUid = user.uid;
      return SessionCheck.accepted;
    } on TimeoutException {
      AppLog.failure('session check', code: 'timeout');
      return SessionCheck.unverified;
    } on FirebaseException catch (error) {
      AppLog.failure('session check', code: error.code, error: error);
      return isRejectedSession(error)
          ? SessionCheck.rejected
          : SessionCheck.unverified;
    }
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    try {
      await _initialiseGoogle();
      final account = await _google.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const SignInFailure(SignInProblem.noGoogleToken);
      }
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      return await _signIn(() => _auth.signInWithCredential(credential));
    } on GoogleSignInException catch (error) {
      throw failureFromGoogleSignIn(error);
    }
  }

  @override
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) => _signIn(
    () => _auth.signInWithEmailAndPassword(email: email, password: password),
  );

  @override
  Future<AuthUser> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final user = await _signIn(
      () => _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      ),
    );
    final created = _auth.currentUser;
    if (created == null) return user;
    try {
      await created.updateDisplayName(displayName.trim());
      await created.sendEmailVerification();
      await created.reload();
    } on FirebaseAuthException catch (error) {
      // The account exists and they are already signed in; only the name or the
      // courtesy verification email did not land. Nothing waits on either
      // (accounts ADR-0007), and failing the registration here would show an
      // error over a session that is live — so this is logged and carried on
      // from, not thrown (`ENG-10`: a decision, not a swallowed error).
      AppLog.failure('register follow-up', code: error.code, error: error);
    }
    return _toAuthUser(_auth.currentUser) ?? user;
  }

  @override
  Future<void> sendPasswordReset(String email) =>
      _guard(() => _auth.sendPasswordResetEmail(email: email.trim()));

  @override
  Future<AuthUser> signInWithSeededUser({
    required String email,
    required String password,
  }) => signInWithEmail(email: email, password: password);

  @override
  Future<AuthUser> signInWithKidToken(String token) async {
    _linking.clear();
    try {
      final credential = await _auth.signInWithCustomToken(token);
      final user = credential.user;
      if (user == null) throw const SignInFailure(SignInProblem.unknown);
      _acceptedUid = user.uid;
      return await _withKidClaim(user) ?? _fromUser(user);
    } on FirebaseAuthException catch (error) {
      throw failureFromFirebaseAuth(error);
    }
  }

  @override
  Future<void> signOut() async {
    _linking.clear();
    _acceptedUid = null;
    // Firebase first: if signing out of Google fails, the app must still not be
    // holding a Firebase session it believes is signed out.
    await _auth.signOut();
    try {
      // A session restored from disk never initialised Google in this process,
      // and the plugin must be before any other call — signing out included.
      await _initialiseGoogle();
      await _google.signOut();
    } on GoogleSignInException catch (error) {
      // Already signed out of Google, or Google is not configured on this
      // build — neither changes the fact that the Firebase session is gone, so
      // it is logged and not thrown (`ENG-10`).
      AppLog.failure('google sign-out', code: error.code.name, error: error);
    }
  }

  Future<void> _initialiseGoogle() async {
    if (_googleIsInitialised) return;
    await _google.initialize();
    _googleIsInitialised = true;
  }

  /// Every way in goes through here, so the pending-credential link happens
  /// once rather than at four call sites (`ENG-01`).
  Future<AuthUser> _signIn(Future<UserCredential> Function() attempt) async {
    try {
      final credential = await attempt();
      final user = credential.user;
      if (user == null) throw const SignInFailure(SignInProblem.cancelled);
      _acceptedUid = user.uid;
      await _linking.linkTo(user);
      return _toAuthUser(_auth.currentUser) ?? _fromUser(user);
    } on FirebaseAuthException catch (error) {
      // Only Google's refusal carries a credential to link. Registering a
      // password over an address Google already has throws `email-already-in-use`
      // with nothing attached, so that direction ends at copy telling the person
      // to use the button they used last time — the asymmetry is Firebase's, and
      // it is named in accounts ADR-0002 rather than papered over by stashing a
      // password in memory until they come back.
      _linking.remember(error);
      throw failureFromFirebaseAuth(error);
    }
  }

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on FirebaseAuthException catch (error) {
      throw failureFromFirebaseAuth(error);
    }
  }

  AuthUser? _toAuthUser(User? user) => user == null ? null : _fromUser(user);

  /// The user, with the kid claim read off its token when it could be a kid
  /// device (accounts ADR-0003). Only a user with no provider at all — which is
  /// what a custom-token sign-in is — pays for the token read, so a Google or
  /// password account's start-up is exactly what it was.
  Future<AuthUser?> _withKidClaim(User? user) async {
    if (user == null) return null;
    final base = _fromUser(user);
    if (user.providerData.isNotEmpty || user.isAnonymous) return base;
    try {
      final token = await user.getIdTokenResult();
      return base.copyWith(kid: KidIdentity.fromClaims(token.claims));
    } on FirebaseAuthException catch (error) {
      // A kid device whose token the backend refuses is signed out like any
      // other dead session, not shown a sign-in error (accounts ADR-0008).
      if (isRejectedSession(error)) throw const SessionExpiredFailure();
      throw failureFromFirebaseAuth(error);
    }
  }

  AuthUser _fromUser(User user) => AuthUser(
    uid: user.uid,
    email: user.email ?? '',
    displayName: user.displayName,
    photoUrl: user.photoURL,
  );
}
