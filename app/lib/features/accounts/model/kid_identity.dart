import 'package:freezed_annotation/freezed_annotation.dart';

part 'kid_identity.freezed.dart';

/// Who a kid device is (accounts ADR-0003): the household it belongs to and
/// the member profile it signs in as. It arrives as the `kidProfile` claim on
/// the device's ID token, which only `redeemKidPairing` ever sets.
///
/// This is how the app knows which home to show. It is never what authorises
/// anything: the rules read the household's `kids` map, which a parent can
/// empty in one tap. Todos phase 2 builds on it — a chore a kid ticks is
/// completed by and for [memberId], and the rules refuse any other name.
@freezed
abstract class KidIdentity with _$KidIdentity {
  const factory KidIdentity({
    required String householdId,
    required String memberId,
  }) = _KidIdentity;

  /// The claim's name on the token, shared with the Functions' `KID_CLAIM`.
  static const claim = 'kidProfile';

  /// The identity a token's claims carry, or null for everybody who is not a
  /// kid device. Parsed, never cast (`ENG-09`): a claim of the wrong shape is
  /// not a kid.
  static KidIdentity? fromClaims(Map<String, Object?>? claims) {
    final value = claims?[claim];
    if (value is! Map) return null;
    final householdId = value['householdId'];
    final memberId = value['memberId'];
    if (householdId is! String || householdId.isEmpty) return null;
    if (memberId is! String || memberId.isEmpty) return null;
    return KidIdentity(householdId: householdId, memberId: memberId);
  }
}
