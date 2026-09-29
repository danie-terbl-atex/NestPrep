import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/tokens/nest_member_palette.dart';
import 'package:nestprep/features/household/model/access_defaults.dart';
import 'package:nestprep/features/household/model/access_grant.dart';
import 'package:nestprep/features/household/model/access_level.dart';
import 'package:nestprep/features/household/model/household.dart';
import 'package:nestprep/features/household/model/household_area.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/features/household/model/member.dart';
import 'package:nestprep/features/household/model/member_role.dart';
import 'package:nestprep/features/household/state/household_controller.dart';
import 'package:nestprep/features/household/state/invite_step_controller.dart';
import 'package:nestprep/features/household/state/member_access_controller.dart';
import 'package:nestprep/features/household/ui/household_screen.dart';
import 'package:nestprep/features/household/ui/invite_step_screen.dart';
import 'package:nestprep/features/household/ui/member_access_screen.dart';
import 'package:provider/provider.dart';

import '../test/support/fake_household.dart';
import '../test/support/fake_invite_sharer.dart';
import '../test/support/household_fixtures.dart';
import 'review_press.dart';

/// Household phase 2's screens as pictures (household ADR-0003): the invite
/// step a new household opens with, the people screen, and one helper's
/// access. Not a test — like `design_review_test.dart`, a press:
///
///     flutter test tool/household_access_review_test.dart --update-goldens
void main() {
  setUpAll(loadEveryFont);

  const grace = Member(
    id: 'm-grace',
    displayName: 'Grace Mokoena',
    color: MemberColor.teal,
    roleName: 'carer',
    claimedBy: 'uid-grace',
  );
  const lindiwe = Member(
    id: 'm-lindiwe',
    displayName: 'Lindiwe Parker',
    color: MemberColor.coral,
    roleName: 'kid',
  );

  HouseholdView household({String? pendingSetupStep}) => HouseholdView(
    household: Fixtures.household().copyWith(
      members: const {
        Fixtures.samUid: 'admin',
        Fixtures.thandiUid: 'helper',
        'uid-grace': 'carer',
      },
      access: {
        Fixtures.thandiUid: AccessGrant({
          HouseholdArea.groceries: AccessLevel.edit,
          HouseholdArea.todos: AccessLevel.own,
          HouseholdArea.homeCare: AccessLevel.own,
        }),
        'uid-grace': AccessDefaults.carer,
      },
      pendingSetupStep: pendingSetupStep,
    ),
    members: [Fixtures.sam, lindiwe, Fixtures.thandi, grace],
    viewerUid: Fixtures.samUid,
  );

  for (final brightness in Brightness.values) {
    testWidgets('the invite step — ${brightness.name}', (tester) async {
      final repository = FakeHouseholdRepository();
      addTearDown(repository.close);
      final controller = InviteStepController(
        householdRepository: repository,
        householdDirectory: FakeHouseholdDirectory(),
        inviteSharer: FakeInviteSharer(),
        householdId: Fixtures.householdId,
        householdName: 'The Parkers',
        coloursInUse: const [MemberColor.violet],
      );
      addTearDown(controller.dispose);

      await captureScreen(
        tester,
        'invite-step-${brightness.name}',
        screen: const InviteStepScreen(),
        providers: [
          ChangeNotifierProvider<InviteStepController>.value(value: controller),
        ],
        view: household(pendingSetupStep: Household.invitePeopleStep),
        brightness: brightness,
        emit: () => controller.invite(
          displayName: 'Alex Parker',
          role: MemberRole.admin,
        ),
      );
    });

    testWidgets('the access editor — ${brightness.name}', (tester) async {
      final controller = MemberAccessController(
        householdDirectory: FakeHouseholdDirectory(),
        householdId: Fixtures.householdId,
        memberId: Fixtures.thandiMemberId,
        startingFrom: household().permissionsOf(Fixtures.thandi).grant!,
      );
      addTearDown(controller.dispose);

      await captureScreen(
        tester,
        'member-access-${brightness.name}',
        screen: const MemberAccessScreen(memberId: Fixtures.thandiMemberId),
        providers: [
          ChangeNotifierProvider<MemberAccessController>.value(
            value: controller,
          ),
        ],
        view: household(),
        brightness: brightness,
        emit: () async {
          controller.setLevel(HouseholdArea.calendar, AccessLevel.view);
        },
      );
    });

    testWidgets('the people — ${brightness.name}', (tester) async {
      final repository = FakeHouseholdRepository();
      addTearDown(repository.close);
      final controller = HouseholdController(
        householdRepository: repository,
        householdDirectory: FakeHouseholdDirectory(),
        householdId: Fixtures.householdId,
        viewerUid: Fixtures.samUid,
      );
      addTearDown(controller.dispose);
      final view = household();

      await captureScreen(
        tester,
        'people-${brightness.name}',
        screen: const HouseholdScreen(),
        providers: [
          ChangeNotifierProvider<HouseholdController>.value(value: controller),
        ],
        view: view,
        brightness: brightness,
        emit: () async {
          repository.emitHousehold(view.household);
          repository.emitMembers(view.members);
        },
      );
    });
  }
}
