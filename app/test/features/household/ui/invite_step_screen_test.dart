import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/household/data/invite_sharer.dart';
import 'package:nestprep/features/household/model/household.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/features/household/model/member_role.dart';
import 'package:nestprep/features/household/state/invite_step_controller.dart';
import 'package:nestprep/features/household/ui/invite_step_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_household.dart';
import '../../../support/fake_invite_sharer.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';

/// The step a new household opens with (household ADR-0003): "who else keeps
/// this house running?", an invite made and shared in two taps, and a way out
/// that is always there.
void main() {
  late FakeHouseholdRepository repository;
  late FakeHouseholdDirectory directory;
  late FakeInviteSharer sharer;
  late InviteStepController controller;

  setUp(() {
    repository = FakeHouseholdRepository();
    directory = FakeHouseholdDirectory();
    sharer = FakeInviteSharer();
    controller = InviteStepController(
      householdRepository: repository,
      householdDirectory: directory,
      inviteSharer: sharer,
      householdId: Fixtures.householdId,
      householdName: 'The Parkers',
      coloursInUse: const [],
    );
  });

  tearDown(() async {
    controller.dispose();
    await repository.close();
  });

  HouseholdView owingTheStep() => HouseholdView(
    household: Fixtures.household().copyWith(
      pendingSetupStep: Household.invitePeopleStep,
    ),
    members: [Fixtures.sam],
    viewerUid: Fixtures.samUid,
  );

  Future<void> pump(
    WidgetTester tester, {
    HouseholdView? view,
    Brightness brightness = Brightness.light,
    double scale = 1,
  }) => pumpRouter(
    tester,
    router: GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const InviteStepScreen(),
        ),
        GoRoute(
          path: '/households/:householdId/:tab',
          builder: (context, state) =>
              Text('landed on ${state.pathParameters['tab']}'),
        ),
      ],
    ),
    providers: [
      ChangeNotifierProvider<InviteStepController>.value(value: controller),
    ],
    view: view ?? owingTheStep(),
    brightness: brightness,
    textScale: scale,
  );

  Future<void> inviteSomebody(
    WidgetTester tester, {
    required String option,
    required String name,
  }) async {
    await tester.tap(find.text(option));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), name);
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.widgetWithText(NestButton, AccessCopy.inviteSend),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(NestButton, AccessCopy.inviteSend));
    await tester.pumpAndSettle();
  }

  testWidgets('asks the question, and offers the people households invite', (
    tester,
  ) async {
    await pump(tester);
    await tester.pumpAndSettle();

    expect(find.text(AccessCopy.setupTitle), findsOneWidget);
    for (final option in [
      AccessCopy.setupPartner,
      AccessCopy.setupGrandparent,
      AccessCopy.setupHelper,
      AccessCopy.setupCarer,
    ]) {
      expect(find.text(option), findsOneWidget, reason: option);
    }
  });

  testWidgets('can be skipped before anybody is invited', (tester) async {
    await pump(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(NestButton, AccessCopy.setupSkip));
    await tester.pumpAndSettle();

    expect(repository.setupStepsFinished, 1);
    // Home is lunch, the launch feature (lunch-box ADR-0004).
    expect(find.text('landed on today'), findsOneWidget);
  });

  testWidgets('a grandparent is suggested as a parent, and shared at once', (
    tester,
  ) async {
    await pump(tester);
    await tester.pumpAndSettle();

    await inviteSomebody(
      tester,
      option: AccessCopy.setupGrandparent,
      name: 'Gogo',
    );

    expect(repository.added.single.role, MemberRole.parent);
    expect(repository.added.single.displayName, 'Gogo');
    expect(sharer.sent.single.text, contains('ABCD2345'));
    expect(find.text('ABCD2345'), findsOneWidget);
    expect(
      find.widgetWithText(NestButton, AccessCopy.setupDone),
      findsOneWidget,
      reason: 'once somebody is invited, the way out says Done',
    );
  });

  testWidgets('the role can be changed before anything is made', (
    tester,
  ) async {
    await pump(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text(AccessCopy.setupPartner));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Alex');
    await tester.tap(find.text(AccessCopy.roleName(MemberRole.parent)));
    await tester.pumpAndSettle();
    expect(find.text(AccessCopy.roleBlurb(MemberRole.parent)), findsOneWidget);
    await tester.ensureVisible(
      find.widgetWithText(NestButton, AccessCopy.inviteSend),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(NestButton, AccessCopy.inviteSend));
    await tester.pumpAndSettle();

    expect(repository.added.single.role, MemberRole.parent);
  });

  testWidgets('a share sheet that will not open says to copy instead', (
    tester,
  ) async {
    sharer.outcome = InviteShareOutcome.unavailable;
    await pump(tester);
    await tester.pumpAndSettle();

    await inviteSomebody(
      tester,
      option: AccessCopy.setupHelper,
      name: 'Thandi',
    );

    expect(find.text(AccessCopy.inviteShareUnavailable), findsOneWidget);
    expect(find.text('ABCD2345'), findsOneWidget);
  });

  testWidgets('a refusal is a sentence, never an exception', (tester) async {
    repository.failWritesWith = const PermissionDeniedFailure();
    await pump(tester);
    await tester.pumpAndSettle();

    await inviteSomebody(
      tester,
      option: AccessCopy.setupHelper,
      name: 'Thandi',
    );

    expect(
      find.text(AppCopy.failure(const PermissionDeniedFailure())),
      findsOneWidget,
    );
    expect(sharer.sent, isEmpty);
  });

  testWidgets('from the people screen it closes no step', (tester) async {
    await pump(tester, view: Fixtures.view());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(NestButton, AccessCopy.setupSkip));
    await tester.pumpAndSettle();

    expect(repository.setupStepsFinished, 0);
  });

  testWidgets('it holds at phone width in dark at 200% text', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await pump(tester, brightness: Brightness.dark, scale: 2);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text(AccessCopy.setupChild), 200);

    expect(tester.takeException(), isNull);
  });
}
