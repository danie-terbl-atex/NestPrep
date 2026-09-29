import '../model/auth_user.dart';

/// What the app needs from Firebase Auth (accounts ADR-0001, ADR-0002). Behind
/// an interface so a widget test can sign a user in without a platform channel.
///
/// Two providers, one account per person: when a credential arrives for an
/// address that already has an account under the other provider, the gateway
/// remembers it and links it onto the existing uid once that provider has
/// signed in — it never creates a second one (accounts ADR-0002).
abstract interface class AuthGateway {
  /// Who is signed in, live. Emits null when nobody is, including at startup
  /// before the SDK has restored a session.
  Stream<AuthUser?> authStateChanges();

  Future<AuthUser> signInWithGoogle();

  /// Signing in with an address and a password. Throws
  /// `SignInProblem.wrongCredentials` for every wrong-credential shape,
  /// because enumeration protection makes them indistinguishable on purpose.
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  });

  /// Creating an account, naming it, and sending the first verification email
  /// in one step — an account that exists with no way to prove its address is a
  /// person stuck behind the household gate with nothing to click.
  Future<AuthUser> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  });

  /// Sends a reset, and says nothing about whether the address had an account:
  /// the screen shows the same sentence either way (accounts ADR-0002).
  Future<void> sendPasswordReset(String email);

  /// Sends another verification email to whoever is signed in.
  Future<void> sendEmailVerification();

  /// Re-reads the signed-in user from Firebase and reports whether the address
  /// has been verified since. The SDK does not push this — the claim changes on
  /// a web page in another app — so the verify screen has to ask.
  Future<bool> refreshEmailVerified();

  /// Whether a credential is waiting to be linked onto the account this address
  /// already has, and which address that is. Null when nothing is pending.
  String? get pendingLinkEmail;

  /// The emulator's stopgap, so local runs and hand-driven tests do not need
  /// Google's OAuth configuration. Kept separate from [signInWithEmail] even
  /// though the SDK call is the same, because the seeded picker is an
  /// emulator-only shortcut and must never become the production form
  /// (accounts ADR-0002).
  Future<AuthUser> signInWithSeededUser({
    required String email,
    required String password,
  });

  /// Signs a kid device in with the custom token `redeemKidPairing` minted for
  /// it (accounts ADR-0003). The user that comes back carries its
  /// [AuthUser.kid]; there is no credential to link and no address.
  Future<AuthUser> signInWithKidToken(String token);

  Future<void> signOut();
}
