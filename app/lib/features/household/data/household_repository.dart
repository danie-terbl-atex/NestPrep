import '../../../design/tokens/nest_member_palette.dart';
import '../model/access_grant.dart';
import '../model/birthday.dart';
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

  /// As many profiles as a household could plausibly have. Every other
  /// listener in the app is bounded (`BE-08`) and this one was not: a member
  /// list is small in practice, and "small in practice" is how an unbounded
  /// read ships. Past this many the household is not a household.
  static const memberLimit = 50;

  /// Every profile in the household, live, ordered by name.
  Stream<List<Member>> watchMembers(String householdId);

  /// One profile, live. Null when it has gone. The one member read a kid
  /// device may make — its own (accounts ADR-0003).
  Stream<Member?> watchMember(String householdId, String memberId);

  /// Adds an unclaimed profile. Admin only, and the rules say so too. A null
  /// birthday is the ordinary case, not a missing one (birthdays ADR-0001). A
  /// kid, helper or carer is written with its grant; family with none
  /// (household ADR-0003). Returns the new profile's id, which the invite step
  /// makes a code for at once.
  Future<String> addMember({
    required String householdId,
    required String displayName,
    required MemberColor color,
    required MemberRole role,
    Birthday? birthday,
    AccessGrant? access,
  });

  /// Renames or recolours a profile, and changes the role — and with it the
  /// grant — of one nobody has claimed. A claimed member's role moves through
  /// `setMemberRole` because it also lives in the household's uid→role map.
  Future<void> updateMember({
    required String householdId,
    required String memberId,
    required String displayName,
    required MemberColor color,
    required MemberRole role,
    Birthday? birthday,
    AccessGrant? access,
  });

  /// Closes the invite step a new household opens, whether it was finished
  /// or skipped (household ADR-0003). Admin only.
  Future<void> finishSetupStep(String householdId);

  /// Renames the household or changes its timezone. Admin only.
  Future<void> updateHousehold({
    required String householdId,
    required String name,
    required String timeZone,
  });
}
