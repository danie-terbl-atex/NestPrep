import '../model/member_role.dart';

/// A new invite: the code to share and when it stops working.
class InviteCode {
  const InviteCode({required this.code, required this.expiresAt});

  final String code;
  final DateTime expiresAt;
}

/// Everything that changes who is in a household. None of it is a client write:
/// each one moves several documents at once, which Security Rules cannot do, so
/// each is a Cloud Function (foundation ADR-0002, household ADR-0002).
abstract interface class HouseholdDirectory {
  /// Creates a household with the caller as its first, already-claimed admin.
  /// Returns the new household's id.
  Future<String> createHousehold({
    required String name,
    required String timeZone,
    required String adminDisplayName,
    required String adminColorName,
  });

  /// A single-use, seven-day code for one unclaimed profile. Admin only.
  Future<InviteCode> createInvite({
    required String householdId,
    required String memberId,
  });

  /// Claims the profile the code was made for. Returns the household joined.
  Future<String> redeemInvite(String code);

  Future<void> leaveHousehold(String householdId);

  Future<void> removeMember({
    required String householdId,
    required String memberId,
  });

  /// Changes a claimed member's role in both the profile and the household's
  /// uid→role map.
  Future<void> setMemberRole({
    required String householdId,
    required String memberId,
    required MemberRole role,
  });
}
