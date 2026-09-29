import 'account.dart';
import 'auth_user.dart';
import 'kid_identity.dart';

/// Who the app is being used by right now. The router switches on this and
/// nothing else (accounts phase 1).
sealed class Session {
  const Session();
}

final class SignedOut extends Session {
  const SignedOut();
}

/// Signed in to Firebase Auth, with the account document that sign-in created
/// or refreshed.
final class SignedIn extends Session {
  const SignedIn({required this.user, required this.account});

  final AuthUser user;
  final Account account;

  String get uid => user.uid;
}

/// Signed in on a kid device (accounts ADR-0003): a profile in one household,
/// with no account document and none of an account's choices. The router sends
/// it to the kid's home and nowhere else.
final class KidSignedIn extends Session {
  const KidSignedIn({required this.uid, required this.kid});

  final String uid;
  final KidIdentity kid;
}
