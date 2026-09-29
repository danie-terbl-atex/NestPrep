import '../model/account.dart';
import '../model/auth_user.dart';

/// What the app needs from `users/{uid}` (accounts ADR-0001).
abstract interface class AccountRepository {
  /// The account document, live. Emits null while it does not exist yet — the
  /// moment between signing in and the document being written.
  Stream<Account?> watch(String uid);

  /// Creates the document on first sign-in, or refreshes what Google tells us
  /// about the person on every sign-in after that. Never touches
  /// `householdIds`, which only Cloud Functions write (household ADR-0002).
  Future<void> ensureAccount(AuthUser user);

  /// Switches which household the app shows. The rules refuse a household this
  /// account does not belong to.
  Future<void> setActiveHousehold({
    required String uid,
    required String householdId,
  });

  /// Records that this person agreed to these versions of the terms and the
  /// privacy policy, stamped with the server's time (accounts ADR-0005). The
  /// rules refuse any other shape, and a version lower than one already
  /// agreed.
  Future<void> acceptLegal({
    required String uid,
    required int termsVersion,
    required int privacyVersion,
  });
}
