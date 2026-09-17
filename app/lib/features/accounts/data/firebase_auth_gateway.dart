import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../shared/failure/app_failure.dart';
import '../model/auth_user.dart';
import 'auth_gateway.dart';
import 'google_sign_in_failure_mapper.dart';

final class FirebaseAuthGateway implements AuthGateway {
  FirebaseAuthGateway(this._auth, {GoogleSignIn? googleSignIn})
    : _google = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _auth;
  final GoogleSignIn _google;
  bool _googleIsInitialised = false;

  @override
  Stream<AuthUser?> authStateChanges() =>
      _auth.authStateChanges().map(_toAuthUser);

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
      return _requireUser(await _auth.signInWithCredential(credential));
    } on GoogleSignInException catch (error) {
      throw failureFromGoogleSignIn(error);
    } on FirebaseAuthException catch (error) {
      throw failureFromFirebaseAuth(error);
    }
  }

  @override
  Future<AuthUser> signInWithSeededUser({
    required String email,
    required String password,
  }) async {
    try {
      return _requireUser(
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        ),
      );
    } on FirebaseAuthException catch (error) {
      throw failureFromFirebaseAuth(error);
    }
  }

  @override
  Future<void> signOut() async {
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

  AuthUser _requireUser(UserCredential credential) {
    final user = _toAuthUser(credential.user);
    if (user == null) throw const SignInFailure(SignInProblem.cancelled);
    return user;
  }

  AuthUser? _toAuthUser(User? user) {
    if (user == null) return null;
    return AuthUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
    );
  }
}
