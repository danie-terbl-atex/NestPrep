import '../model/auth_user.dart';

/// What the app needs from Firebase Auth (accounts ADR-0001). Behind an
/// interface so a widget test can sign a user in without a platform channel.
abstract interface class AuthGateway {
  /// Who is signed in, live. Emits null when nobody is, including at startup
  /// before the SDK has restored a session.
  Stream<AuthUser?> authStateChanges();

  /// Google is the only way in for a real build.
  Future<AuthUser> signInWithGoogle();

  /// The emulator's stopgap, so local runs and hand-driven tests do not need
  /// Google's OAuth configuration. The cloud project never enables this
  /// provider, and the sign-in screen only offers it on an emulator build
  /// (accounts ADR-0001).
  Future<AuthUser> signInWithSeededUser({
    required String email,
    required String password,
  });

  Future<void> signOut();
}
