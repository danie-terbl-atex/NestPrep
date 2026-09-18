import '../../../design/tokens/nest_member_palette.dart';
import '../model/household.dart';
import '../model/member.dart';
import '../model/member_role.dart';

/// What the app reads directly from Firestore about a household. Everything
/// that changes membership is a callable instead (household ADR-0002) —
/// `HouseholdDirectory`.
abstract interface class HouseholdRepository {
  /// The household document, live. Emits null when it is gone or unreadable
  /// because this account is no longer a member.
  Stream<Household?> watchHousehold(String householdId);

  /// The households this account belongs to, by name, for choosing between
  /// them. A one-off read rather than a listener: nobody is watching the list
  /// of households they are in while they read it, and the ids come from the
  /// account document, which *is* live.
  Future<List<Household>> readHouseholds(List<String> householdIds);

  /// Every profile in the household, live, ordered by name.
  Stream<List<Member>> watchMembers(String householdId);

  /// Adds an unclaimed profile. Admin only, and the rules say so too.
  Future<void> addMember({
    required String householdId,
    required String displayName,
    required MemberColor color,
    required MemberRole role,
  });

  /// Renames or recolours a profile, and changes the role of one nobody has
  /// claimed. A claimed member's role moves through `setMemberRole` because it
  /// also lives in the household's uid→role map.
  Future<void> updateMember({
    required String householdId,
    required String memberId,
    required String displayName,
    required MemberColor color,
    required MemberRole role,
  });

  /// Renames the household or changes its timezone. Admin only.
  Future<void> updateHousehold({
    required String householdId,
    required String name,
    required String timeZone,
  });
}
