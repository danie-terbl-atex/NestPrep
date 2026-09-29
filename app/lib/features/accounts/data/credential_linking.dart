import 'package:firebase_auth/firebase_auth.dart';

import '../../../shared/log/app_log.dart';

/// Holds the credential that could not sign in because its address already has
/// an account under the other provider, and links it once that provider has.
///
/// This is what *one person is one account* costs (accounts ADR-0002). Every
/// rule and all six callables key on `request.auth.uid`, so letting the second
/// credential make a second uid would give one person two sets of household
/// memberships and no screen in this app could repair it.
///
/// The link is deliberately **not** silent. A credential is attached only after
/// the person has signed in with the provider the address already has, which is
/// a real re-authentication — attaching a credential to an account on the
/// strength of a matching email alone is how account takeover works.
final class CredentialLinking {
  AuthCredential? _pending;
  String? _pendingEmail;

  /// The address whose account is waiting for a link, or null when none is.
  String? get pendingEmail => _pendingEmail;

  /// Remembers the credential Firebase refused, if the error carried one. Some
  /// refusals have no credential attached, and there is nothing to link then —
  /// the person simply signs in the other way.
  void remember(FirebaseAuthException error) {
    final credential = error.credential;
    final email = error.email;
    if (credential == null || email == null) return;
    _pending = credential;
    _pendingEmail = email;
    AppLog.failure('auth link pending', code: error.code, error: error);
  }

  /// Links anything pending onto the user who has just signed in, when it is
  /// the same address. A link that fails is swallowed *as a link* and not as a
  /// sign-in: the person is signed in either way, and failing the whole sign-in
  /// because the second provider could not be attached would be a worse
  /// outcome than having one way in instead of two.
  Future<void> linkTo(User user) async {
    final pending = _pending;
    final email = _pendingEmail;
    if (pending == null || email == null) return;
    if (user.email?.toLowerCase() != email.toLowerCase()) return;

    _pending = null;
    _pendingEmail = null;
    try {
      await user.linkWithCredential(pending);
    } on FirebaseAuthException catch (error) {
      // Already linked, or the provider was attached from another device in the
      // meantime. Both mean the account has the credential; neither is worth
      // interrupting somebody who is now signed in (`ENG-10` — this is a
      // decision to continue, not a swallowed error: it is logged).
      AppLog.failure('auth link', code: error.code, error: error);
    }
  }

  /// Forgets anything pending. Called on sign-out, so a credential cannot
  /// survive into somebody else's session on a shared phone.
  void clear() {
    _pending = null;
    _pendingEmail = null;
  }
}
