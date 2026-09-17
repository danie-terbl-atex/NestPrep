import 'household.dart';
import 'member.dart';
import 'member_role.dart';

/// The household and its profiles together — what every household screen needs
/// and what the controller's one `AsyncState` carries, so a screen never has to
/// reconcile two loading states.
class HouseholdView {
  const HouseholdView({
    required this.household,
    required this.members,
    required this.viewerUid,
  });

  final Household household;
  final List<Member> members;
  final String viewerUid;

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
}
