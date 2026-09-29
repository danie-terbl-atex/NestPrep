import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/app_log.dart';
import '../model/auth_user.dart';
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

  @override
  Stream<AuthUser?> authStateChanges() =>
      _auth.authStateChanges().map(_toAuthUser);

  @override
  String? get pendingLinkEmail => _linking.pendingEmail;

  @override
  Future<AuthUser> signInWithGoogle() async {
    try {
      if (!_googleIsInitialised) {
        await _google.initialize();
        _googleIsInitialised = true;
      }
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
      // first verification email did not land. Failing the registration here
      // would show an error over a session that is live, and the verify screen
      // can send another email — so this is logged and carried on from, not
      // thrown (`ENG-10`: a decision, not a swallowed error).
      AppLog.failure('register follow-up', code: error.code, error: error);
    }
    return _toAuthUser(_auth.currentUser) ?? user;
  }

  @override
  Future<void> sendPasswordReset(String email) =>
      _guard(() => _auth.sendPasswordResetEmail(email: email.trim()));

  @override
  Future<void> sendEmailVerification() => _guard(() async {
    final user = _auth.currentUser;
    if (user == null) throw const SignInFailure(SignInProblem.unknown);
    await user.sendEmailVerification();
  });

  @override
  Future<bool> refreshEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await _guard(user.reload);
    // The claim the callables read lives in the token, not the user record, so
    // a stale token would still be refused after the person verified. Forcing a
    // refresh here is what makes the "I have verified" button actually work.
    await _guard(() => user.getIdToken(true));
    return _auth.currentUser?.emailVerified ?? false;
  }

  @override
  Future<AuthUser> signInWithSeededUser({
    required String email,
    required String password,
  }) => signInWithEmail(email: email, password: password);

  @override
  Future<void> signOut() async {
    _linking.clear();
    // Firebase first: if signing out of Google fails, the app must still not be
    // holding a Firebase session it believes is signed out.
    await _auth.signOut();
    try {
      await _google.signOut();
    } on GoogleSignInException {
      // Already signed out of Google, or Google was never used on this build —
      // neither changes the fact that the Firebase session is gone.
    }
  }

  /// Every way in goes through here, so the pending-credential link happens
  /// once rather than at four call sites (`ENG-01`).
  Future<AuthUser> _signIn(Future<UserCredential> Function() attempt) async {
    try {
      final credential = await attempt();
      final user = credential.user;
      if (user == null) throw const SignInFailure(SignInProblem.cancelled);
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

  AuthUser _fromUser(User user) => AuthUser(
    uid: user.uid,
    email: user.email ?? '',
    displayName: user.displayName,
    photoUrl: user.photoURL,
    emailVerified: user.emailVerified,
  );
}
