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
import 'package:nestprep/features/subscriptions/model/entitlement.dart';
import 'package:nestprep/features/subscriptions/model/entitlement_status.dart';
import 'package:nestprep/features/subscriptions/model/premium_feature.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/subscription_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_family_profiles.dart';
import '../../../support/fake_household.dart';
import '../../../support/fake_invite_sharer.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';
import '../../../support/pump_subscriptions.dart';

/// The step a new household opens with (household ADR-0003): "who else keeps
/// this house running?", an invite made and shared in two taps, and a way out
/// that is always there.
void main() {
  late FakeHouseholdRepository repository;
  late FakeHouseholdDirectory directory;
  late FakeInviteSharer sharer;
  late FakeFamilyProfileRepository children;
  late InviteStepController controller;

  setUp(() {
    repository = FakeHouseholdRepository();
    directory = FakeHouseholdDirectory();
    sharer = FakeInviteSharer();
    children = FakeFamilyProfileRepository();
    controller = InviteStepController(
      householdRepository: repository,
      householdDirectory: directory,
      childProfileDirectory: children,
      inviteSharer: sharer,
      householdId: Fixtures.householdId,
      householdName: 'The Parkers',
      coloursInUse: const [],
      viewerMemberId: Fixtures.samMemberId,
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

  Future<void> inviteAKid(WidgetTester tester) async {
    await tester.tap(find.text(AccessCopy.setupPartner));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Lulu');
    await tester.tap(find.text(AccessCopy.roleName(MemberRole.kid)));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(LegalCopy.guardianConsentLabel));
    await tester.tap(find.text(LegalCopy.guardianConsentLabel));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.widgetWithText(NestButton, AccessCopy.inviteSend),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(NestButton, AccessCopy.inviteSend));
    await tester.pumpAndSettle();
  }

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

  group(
    'an invited kid is in lunches before they join (household ADR-0009)',
    () {
      testWidgets('inviting a kid marks them a child, and shares the code', (
        tester,
      ) async {
        await pump(tester);
        await tester.pumpAndSettle();

        await inviteAKid(tester);

        expect(repository.added.single.role, MemberRole.kid);
        expect(children.writes.single.$2, {
          'memberId': 'm-new-1',
          'isChild': true,
        });
        expect(sharer.sent.single.text, contains('ABCD2345'));
      });
    },
  );

  group('the free plan’s four people (subscriptions ADR-0008)', () {
    HouseholdView ofFour() => Fixtures.view(
      members: [
        Fixtures.sam,
        Fixtures.thandi,
        Fixtures.kid,
        Fixtures.kid.copyWith(id: 'm-gogo', displayName: 'Gogo'),
      ],
    );

    late ValueNotifier<HouseholdView> household;
    final paywall = find.text(
      SubscriptionCopy.headline(PremiumFeature.householdSize),
    );
    final refusal = find.text(AppCopy.failure(const PermissionDeniedFailure()));
    final activePremium = Entitlement(
      premiumUntil: DateTime.now().add(const Duration(days: 30)),
      status: EntitlementStatus.active,
      willRenew: true,
    );

    Future<SubscriptionHarness> pumpWithPremiumOnSale(
      WidgetTester tester, {
      required HouseholdView view,
      Entitlement entitlement = Entitlement.free,
      Brightness brightness = Brightness.light,
      double scale = 1,
    }) async {
      final premium = SubscriptionHarness(entitlement: entitlement);
      household = ValueNotifier(view);
      addTearDown(household.dispose);
      await pumpRouter(
        tester,
        router: GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => ValueListenableBuilder(
                valueListenable: household,
                builder: (context, view, _) => Provider<HouseholdView>.value(
                  value: view,
                  child: const InviteStepScreen(),
                ),
              ),
            ),
          ],
        ),
        providers: [
          ChangeNotifierProvider<InviteStepController>.value(value: controller),
          ...premium.providers,
        ],
        view: view,
        brightness: brightness,
        textScale: scale,
      );
      await tester.pumpAndSettle();
      return premium;
    }

    testWidgets('at four every option stays, locked, and opens Premium '
        'instead of the form', (tester) async {
      tester.view.physicalSize = const Size(420 * 3, 1600 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final premium = await pumpWithPremiumOnSale(tester, view: ofFour());

      expect(find.text(AccessCopy.setupHelper), findsOneWidget);
      expect(find.byIcon(LucideIcons.circlePlus), findsNothing);
      final locks = tester.widgetList<Icon>(find.byIcon(LucideIcons.lock));
      expect(locks, hasLength(5));
      expect(
        locks.map((lock) => lock.semanticLabel),
        everyElement(SubscriptionCopy.lockedHint),
      );

      await tester.tap(find.text(AccessCopy.setupHelper));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNothing);
      expect(
        find.text(SubscriptionCopy.headline(PremiumFeature.householdSize)),
        findsOneWidget,
      );
      expect(
        premium.paywallOpens.opened.single.trigger,
        PremiumFeature.householdSize,
      );
      expect(repository.added, isEmpty);
    });

    testWidgets('with three there is no lock', (tester) async {
      await pumpWithPremiumOnSale(tester, view: Fixtures.view());
      expect(find.byIcon(LucideIcons.lock), findsNothing);
      expect(find.byIcon(LucideIcons.circlePlus), findsNWidgets(5));
    });

    testWidgets('a Premium household of four invites a fifth', (tester) async {
      await pumpWithPremiumOnSale(
        tester,
        view: ofFour(),
        entitlement: Entitlement(
          premiumUntil: DateTime.now().add(const Duration(days: 30)),
          status: EntitlementStatus.active,
          willRenew: true,
        ),
      );
      expect(find.byIcon(LucideIcons.lock), findsNothing);

      await inviteSomebody(
        tester,
        option: AccessCopy.setupHelper,
        name: 'Nomsa',
      );
      expect(repository.added.single.displayName, 'Nomsa');
    });

    testWidgets('a fifth the rules refuse, because somebody else added the '
        'fourth while the form was open, is answered with Premium, and '
        'nobody is invited', (tester) async {
      tester.view.physicalSize = const Size(420 * 3, 1600 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final premium = await pumpWithPremiumOnSale(
        tester,
        view: Fixtures.view(),
      );
      repository.failWritesWith = const PermissionDeniedFailure();

      await tester.tap(find.text(AccessCopy.setupHelper));
      await tester.pumpAndSettle();
      household.value = ofFour();
      await tester.enterText(find.byType(TextField), 'Nomsa');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(NestButton, AccessCopy.inviteSend));
      await tester.pumpAndSettle();

      expect(paywall, findsOneWidget);
      expect(
        premium.paywallOpens.opened.single.trigger,
        PremiumFeature.householdSize,
      );
      expect(controller.actionFailure, isNull);
      expect(sharer.sent, isEmpty);
    });

    testWidgets('with room left, a refusal is the ordinary one — the plan is '
        'not why', (tester) async {
      final premium = await pumpWithPremiumOnSale(
        tester,
        view: Fixtures.view(),
      );
      repository.failWritesWith = const PermissionDeniedFailure();

      await inviteSomebody(
        tester,
        option: AccessCopy.setupHelper,
        name: 'Nomsa',
      );

      expect(refusal, findsOneWidget);
      expect(paywall, findsNothing);
      expect(premium.paywallOpens.opened, isEmpty);
    });

    testWidgets('a Premium household that is refused is told so, in the '
        'ordinary words, and is never sold the plan it has', (tester) async {
      final premium = await pumpWithPremiumOnSale(
        tester,
        view: ofFour(),
        entitlement: activePremium,
      );
      repository.failWritesWith = const PermissionDeniedFailure();

      await inviteSomebody(
        tester,
        option: AccessCopy.setupHelper,
        name: 'Nomsa',
      );

      expect(refusal, findsOneWidget);
      expect(paywall, findsNothing);
      expect(premium.paywallOpens.opened, isEmpty);
      expect(controller.actionFailure, isA<PermissionDeniedFailure>());
    });

    testWidgets('the locked options hold at phone width in dark at 200% text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360 * 3, 800 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await pumpWithPremiumOnSale(
        tester,
        view: ofFour(),
        brightness: Brightness.dark,
        scale: 2,
      );
      await tester.scrollUntilVisible(find.text(AccessCopy.setupChild), 200);
      expect(tester.takeException(), isNull);
    });
  });
}
