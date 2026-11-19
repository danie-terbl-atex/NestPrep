import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/accounts/state/register_controller.dart';
import 'package:nestprep/features/accounts/ui/register_screen.dart';
import 'package:nestprep/features/calendar_sync/model/calendar_connection.dart';
import 'package:nestprep/features/calendar_sync/model/calendar_provider.dart';
import 'package:nestprep/features/calendar_sync/state/connected_calendars_controller.dart';
import 'package:nestprep/features/household/model/household.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/features/household/model/member_role.dart';
import 'package:nestprep/features/household/state/household_controller.dart';
import 'package:nestprep/features/household/state/invite_step_controller.dart';
import 'package:nestprep/features/onboarding/state/setup_flow_controller.dart';
import 'package:nestprep/features/onboarding/ui/setup_flow_screen.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../test/support/fake_auth.dart';
import '../test/support/fake_calendar_sync.dart';
import '../test/support/fake_family_profiles.dart';
import '../test/support/fake_household.dart';
import '../test/support/fake_invite_sharer.dart';
import '../test/support/fake_link_opener.dart';
import '../test/support/household_fixtures.dart';
import 'review_press.dart';

/// The creator's way in (onboarding ADR-0001) with Twig on every step
/// (design-system ADR-0026): the account, the setup flow's family, calendar
/// and payoff, in both themes, and the family at 200% text. The promises and
/// the household gate are in their own presses. Regenerate with
///
///     flutter test tool/onboarding_design_review_test.dart --update-goldens
void main() {
  setUpAll(() async {
    tz_data.initializeTimeZones();
    await loadEveryFont();
  });

  final lulu = Fixtures.sam.copyWith(
    id: 'm-lulu',
    displayName: 'Lulu',
    roleName: MemberRole.kid.name,
    color: MemberColor.amber,
    claimedBy: null,
  );

  HouseholdView newHousehold({bool withChild = false}) => HouseholdView(
    household: Fixtures.household().copyWith(
      name: 'The Parkers',
      pendingSetupStep: Household.invitePeopleStep,
    ),
    members: [Fixtures.sam, if (withChild) lulu],
    viewerUid: Fixtures.samUid,
  );

  Future<void> setup(
    WidgetTester tester,
    String name, {
    required SetupPanel panel,
    Brightness brightness = Brightness.light,
    double textScale = 1,
  }) async {
    final households = FakeHouseholdRepository();
    final calendarRepository = FakeCalendarSyncRepository();
    addTearDown(households.close);
    addTearDown(calendarRepository.close);
    final invites = InviteStepController(
      householdRepository: households,
      householdDirectory: FakeHouseholdDirectory(),
      childProfileDirectory: FakeFamilyProfileRepository(),
      inviteSharer: FakeInviteSharer(),
      householdId: Fixtures.householdId,
      householdName: 'The Parkers',
      coloursInUse: const [MemberColor.violet],
      viewerMemberId: Fixtures.samMemberId,
    );
    final household = HouseholdController(
      householdRepository: households,
      householdDirectory: FakeHouseholdDirectory(),
      childProfileDirectory: FakeFamilyProfileRepository(),
      householdId: Fixtures.householdId,
      viewerUid: Fixtures.samUid,
    );
    final calendars = ConnectedCalendarsController(
      calendarSyncRepository: calendarRepository,
      calendarSyncDirectory: FakeCalendarSyncDirectory(),
      linkOpener: FakeLinkOpener(),
      householdId: Fixtures.householdId,
      viewerUid: Fixtures.samUid,
      isAdmin: true,
    );
    final flow = SetupFlowController();
    for (var i = 0; i < panel.index; i++) {
      flow.next();
    }
    if (panel == SetupPanel.family) flow.noteAdded('Lulu');
    addTearDown(invites.dispose);
    addTearDown(household.dispose);
    addTearDown(calendars.dispose);
    addTearDown(flow.dispose);

    await captureScreen(
      tester,
      name,
      brightness: brightness,
      textScale: textScale,
      view: newHousehold(withChild: true),
      screen: const SetupFlowScreen(),
      providers: [
        ChangeNotifierProvider<InviteStepController>.value(value: invites),
        ChangeNotifierProvider<HouseholdController>.value(value: household),
        ChangeNotifierProvider<ConnectedCalendarsController>.value(
          value: calendars,
        ),
        ChangeNotifierProvider<SetupFlowController>.value(value: flow),
      ],
      emit: () async {
        if (panel == SetupPanel.family) return;
        calendarRepository.emitConnections([
          const CalendarConnection(
            id: 'c1',
            provider: CalendarProvider.google,
            memberId: Fixtures.samMemberId,
            ownerUid: Fixtures.samUid,
            accountLabel: 'sam@gmail.com',
            eventCount: 23,
          ),
        ]);
      },
    );
  }

  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    testWidgets('onboarding-account-$theme', (tester) async {
      final auth = FakeAuthGateway();
      addTearDown(auth.close);
      final controller = RegisterController(authGateway: auth);
      addTearDown(controller.dispose);
      await captureScreen(
        tester,
        'onboarding-account-$theme',
        brightness: brightness,
        screen: ChangeNotifierProvider.value(
          value: controller,
          child: const RegisterScreen(),
        ),
        providers: const [],
        emit: () async {},
      );
    });

    for (final panel in SetupPanel.values) {
      testWidgets('onboarding-${panel.name}-$theme', (tester) async {
        await setup(
          tester,
          'onboarding-${panel.name}-$theme',
          panel: panel,
          brightness: brightness,
        );
      });
    }
  }

  testWidgets('onboarding-family-dark-200-percent-text', (tester) async {
    await setup(
      tester,
      'onboarding-family-dark-200-percent-text',
      panel: SetupPanel.family,
      brightness: Brightness.dark,
      textScale: 2,
    );
  });
}
