import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/calendar_sync/model/calendar_connection.dart';
import 'package:nestprep/features/calendar_sync/model/calendar_provider.dart';
import 'package:nestprep/features/calendar_sync/model/provider_availability.dart';
import 'package:nestprep/features/calendar_sync/state/connected_calendars_controller.dart';
import 'package:nestprep/features/calendar_sync/ui/provider_connect_row.dart';
import 'package:nestprep/features/household/model/household.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/features/household/model/member_role.dart';
import 'package:nestprep/features/household/state/household_controller.dart';
import 'package:nestprep/features/household/state/invite_step_controller.dart';
import 'package:nestprep/features/onboarding/model/onboarding_step.dart';
import 'package:nestprep/features/onboarding/state/setup_flow_controller.dart';
import 'package:nestprep/features/onboarding/ui/setup_flow_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:provider/provider.dart';

import '../../../support/bring_into_view.dart';
import '../../../support/fake_calendar_sync.dart';
import '../../../support/fake_family_profiles.dart';
import '../../../support/fake_household.dart';
import '../../../support/fake_invite_sharer.dart';
import '../../../support/fake_link_opener.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';

/// A new household's setup step (onboarding ADR-0001): family, then
/// calendar, then the payoff, under one bar; only *Open my week* closes it.
void main() {
  late FakeHouseholdRepository households;
  late FakeHouseholdDirectory directory;
  late FakeFamilyProfileRepository profiles;
  late FakeCalendarSyncRepository calendarRepository;
  late FakeCalendarSyncDirectory calendarDirectory;
  late InviteStepController invites;
  late HouseholdController household;
  late ConnectedCalendarsController calendars;
  late SetupFlowController flow;

  setUp(() {
    households = FakeHouseholdRepository();
    directory = FakeHouseholdDirectory();
    profiles = FakeFamilyProfileRepository();
    calendarRepository = FakeCalendarSyncRepository();
    calendarDirectory = FakeCalendarSyncDirectory();
    invites = InviteStepController(
      householdRepository: households,
      householdDirectory: directory,
      childProfileDirectory: profiles,
      inviteSharer: FakeInviteSharer(),
      householdId: Fixtures.householdId,
      householdName: 'The Parkers',
      coloursInUse: const [],
      viewerMemberId: Fixtures.samMemberId,
    );
    household = HouseholdController(
      householdRepository: households,
      householdDirectory: directory,
      childProfileDirectory: profiles,
      householdId: Fixtures.householdId,
      viewerUid: Fixtures.samUid,
    );
    flow = SetupFlowController();
  });

  tearDown(() async {
    invites.dispose();
    household.dispose();
    calendars.dispose();
    flow.dispose();
    await households.close();
    await calendarRepository.close();
  });

  HouseholdView newHousehold() => HouseholdView(
    household: Fixtures.household().copyWith(
      pendingSetupStep: Household.invitePeopleStep,
    ),
    members: [Fixtures.sam],
    viewerUid: Fixtures.samUid,
  );

  Future<void> pump(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    double scale = 1,
  }) async {
    calendars = ConnectedCalendarsController(
      calendarSyncRepository: calendarRepository,
      calendarSyncDirectory: calendarDirectory,
      linkOpener: FakeLinkOpener(),
      householdId: Fixtures.householdId,
      viewerUid: Fixtures.samUid,
      isAdmin: true,
    );
    await pumpRouter(
      tester,
      router: GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const SetupFlowScreen(),
          ),
          GoRoute(
            path: '/households/:householdId/:tab',
            builder: (context, state) =>
                Text('landed on ${state.pathParameters['tab']}'),
          ),
        ],
      ),
      providers: [
        ChangeNotifierProvider<InviteStepController>.value(value: invites),
        ChangeNotifierProvider<HouseholdController>.value(value: household),
        ChangeNotifierProvider<ConnectedCalendarsController>.value(
          value: calendars,
        ),
        ChangeNotifierProvider<SetupFlowController>.value(value: flow),
      ],
      view: newHousehold(),
      brightness: brightness,
      textScale: scale,
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapButton(WidgetTester tester, String label) async {
    final button = find.widgetWithText(NestButton, label);
    await bringIntoView(tester, button);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  String barLabel(CreatorStep step) => step.label;

  testWidgets('walks family, calendar and the payoff under one bar, and only '
      'Open my week closes the step', (tester) async {
    await pump(tester);
    expect(find.text(barLabel(CreatorStep.family)), findsOneWidget);
    expect(find.text(OnboardingCopy.familyTitle), findsOneWidget);

    await tapButton(tester, OnboardingCopy.skip);
    expect(find.text(barLabel(CreatorStep.calendar)), findsOneWidget);
    expect(find.text(OnboardingCopy.calendarTitle), findsOneWidget);
    expect(households.setupStepsFinished, 0);

    await tapButton(tester, OnboardingCopy.skip);
    expect(find.text(OnboardingCopy.readyTitle), findsOneWidget);
    expect(
      find.text(barLabel(CreatorStep.calendar)),
      findsOneWidget,
      reason: 'the payoff keeps the bar full',
    );
    expect(find.text(OnboardingCopy.readyPeople(0)), findsOneWidget);
    expect(find.text(OnboardingCopy.readyCalendars(0)), findsOneWidget);
    expect(households.setupStepsFinished, 0);

    await tapButton(tester, OnboardingCopy.readyOpen);
    expect(households.setupStepsFinished, 1);
    expect(find.textContaining('landed on'), findsOneWidget);
  });

  testWidgets('back goes one panel back and closes nothing', (tester) async {
    await pump(tester);
    await tapButton(tester, OnboardingCopy.skip);
    await tapButton(tester, OnboardingCopy.skip);
    await tapButton(tester, AppCopy.back);
    expect(find.text(OnboardingCopy.calendarTitle), findsOneWidget);
    await tapButton(tester, AppCopy.back);
    expect(find.text(OnboardingCopy.familyTitle), findsOneWidget);
    expect(households.setupStepsFinished, 0);
  });

  testWidgets('a child without a phone is a kid profile, a child at once, and '
      'no invite (household ADR-0009)', (tester) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pump(tester);
    households.emitMembers([Fixtures.sam]);
    await tester.pumpAndSettle();
    await bringIntoView(tester, find.text(OnboardingCopy.familyAddChild));
    await tester.tap(find.text(OnboardingCopy.familyAddChild));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Lulu');
    await tester.ensureVisible(find.text(LegalCopy.guardianConsentLabel));
    await tester.pumpAndSettle();
    await tester.tap(find.text(LegalCopy.guardianConsentLabel));
    await tester.pumpAndSettle();
    final save = find.widgetWithText(NestButton, AppCopy.householdSave);
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();

    final added = households.added.single;
    expect(added.displayName, 'Lulu');
    expect(added.role, MemberRole.kid);
    expect(added.guardianConsent, isNotNull);
    expect(
      profiles.writes.where((write) => write.$1 == 'setIsChild'),
      hasLength(1),
    );
    expect(directory.invitesMade, isEmpty);
    expect(find.text(OnboardingCopy.twigFamilyAdded('Lulu')), findsOneWidget);
    final next = find.widgetWithText(NestButton, OnboardingCopy.next);
    await bringIntoView(tester, next);
    expect(next, findsOneWidget);
  });

  testWidgets('the calendar step offers only what can be connected, and says '
      'when a calendar lands', (tester) async {
    calendarDirectory.availability = const ProviderAvailability(
      google: false,
      microsoft: true,
    );
    await pump(tester);
    await tapButton(tester, OnboardingCopy.skip);

    final offered = tester
        .widgetList<ProviderConnectRow>(find.byType(ProviderConnectRow))
        .map((row) => row.provider);
    expect(offered, [CalendarProvider.microsoft, CalendarProvider.ics]);

    calendarRepository.emitConnections([
      const CalendarConnection(
        id: 'c1',
        provider: CalendarProvider.microsoft,
        memberId: Fixtures.samMemberId,
        ownerUid: Fixtures.samUid,
        accountLabel: 'sam@example.com',
        eventCount: 12,
      ),
    ]);
    await tester.pumpAndSettle();
    expect(
      find.text(OnboardingCopy.twigCalendarIn(CalendarProvider.microsoft)),
      findsOneWidget,
    );
    await tapButton(tester, OnboardingCopy.calendarNext);
    expect(find.text(OnboardingCopy.readyCalendars(1)), findsOneWidget);
  });

  for (final panel in SetupPanel.values) {
    testWidgets('${panel.name} holds at phone width in dark at 200% text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pump(tester, brightness: Brightness.dark, scale: 2);
      for (var i = 0; i < panel.index; i++) {
        flow.next();
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
    });
  }
}
