import '../model/kid_pairing.dart';

/// The kid sign-in callables (accounts ADR-0003). Behind an interface so a
/// widget test pairs a device without a platform channel.
///
/// Everything here is a Cloud Function because a rule cannot mint a token,
/// cannot make an Auth user, and cannot move a code, a device and a household
/// map entry at once (foundation ADR-0002).
abstract interface class KidSignInDirectory {
  /// An admin makes a ten-minute code for one kid profile.
  Future<KidPairing> createPairing({
    required String householdId,
    required String memberId,
    required String label,
  });

  /// Retires a code nobody used. Safe to call for one already gone.
  Future<void> cancelPairing({
    required String householdId,
    required String code,
  });

  /// A signed-out kid device trades a code for the custom token it signs in
  /// with.
  Future<String> redeem(String code);

  /// An admin signs one device out.
  Future<void> revokeDevice({
    required String householdId,
    required String deviceUid,
  });

  /// An admin signs every device of one profile out and retires its code.
  Future<void> resetSignIn({
    required String householdId,
    required String memberId,
  });
}
