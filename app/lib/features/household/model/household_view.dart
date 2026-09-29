import 'household.dart';
import 'household_permissions.dart';
import 'member.dart';
import 'member_role.dart';

/// The household and its profiles together — what every household screen needs
/// and what the controller's one `AsyncState` carries, so a screen never has to
/// reconcile two loading states.
class HouseholdView {
  HouseholdView({
    required this.household,
    required this.members,
    required this.viewerUid,
  });

  final Household household;
  final List<Member> members;
  final String viewerUid;

  /// What the viewer may see and do here, area by area (household ADR-0003).
  /// Worked out once per emission rather than on every build (`FE-12`).
  late final HouseholdPermissions permissions = HouseholdPermissions.of(
    household,
    viewerUid,
  );

  MemberRole? get viewerRole => household.roleOf(viewerUid);

  bool get viewerIsAdmin => household.isAdmin(viewerUid);

  /// The profile the signed-in account claimed here, if it claimed one.
  Member? get viewerMember =>
      members.where((member) => member.isClaimedBy(viewerUid)).firstOrNull;

  List<Member> get unclaimedMembers =>
      members.where((member) => !member.isClaimed).toList();

  bool get isTheOnlyAdmin =>
      viewerIsAdmin &&
      household.members.values
              .where((role) => role == MemberRole.admin.name)
              .length ==
          1;

  Member? memberById(String memberId) =>
      members.where((member) => member.id == memberId).firstOrNull;

  /// The grant a member holds as the rules see it: the household's record for
  /// a claimed member, the profile's own choice for one nobody has claimed.
  /// Null for family.
  HouseholdPermissions permissionsOf(Member member) {
    final uid = member.claimedBy;
    if (uid != null) return HouseholdPermissions.of(household, uid);
    return HouseholdPermissions.unclaimed(member);
  }

  /// A helper claimed before household ADR-0003, whom no parent has yet given
  /// a grant: they keep everything until somebody chooses.
  bool isAwaitingAccessChoice(Member member) {
    final uid = member.claimedBy;
    return uid != null &&
        member.role.isRestricted &&
        !household.access.containsKey(uid);
  }
}
