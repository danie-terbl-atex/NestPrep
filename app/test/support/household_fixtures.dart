import 'package:nestprep/design/tokens/nest_member_palette.dart';
import 'package:nestprep/features/household/model/household.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/features/household/model/member.dart';
import 'package:nestprep/features/household/model/member_role.dart';

/// The household every feature test renders against: Sam an admin who has
/// signed in, Thandi a helper who has, Kid a profile nobody has claimed — the
/// three cases the rules and the screens both care about.
abstract final class Fixtures {
  static const householdId = 'h1';
  static const samUid = 'uid-sam';
  static const thandiUid = 'uid-thandi';
  static const samMemberId = 'm-sam';
  static const thandiMemberId = 'm-thandi';
  static const kidMemberId = 'm-kid';

  static Member get sam => const Member(
    id: samMemberId,
    displayName: 'Sam Parent',
    color: MemberColor.violet,
    roleName: 'admin',
    claimedBy: samUid,
  );

  static Member get thandi => const Member(
    id: thandiMemberId,
    displayName: 'Thandi Helper',
    color: MemberColor.mint,
    roleName: 'helper',
    claimedBy: thandiUid,
  );

  static Member get kid => const Member(
    id: kidMemberId,
    displayName: 'Kid Parker',
    color: MemberColor.sky,
    roleName: 'member',
  );

  static Household household({String timeZone = 'Africa/Johannesburg'}) =>
      Household(
        id: householdId,
        name: 'The Parkers',
        timeZone: timeZone,
        members: const {samUid: 'admin', thandiUid: 'helper'},
        createdBy: samUid,
      );

  static HouseholdView view({
    String viewerUid = samUid,
    List<Member>? members,
    String timeZone = 'Africa/Johannesburg',
  }) => HouseholdView(
    household: household(timeZone: timeZone),
    members: members ?? [sam, thandi, kid],
    viewerUid: viewerUid,
  );

  static MemberRole get adminRole => MemberRole.admin;
}
