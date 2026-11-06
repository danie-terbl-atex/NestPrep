import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/app/household_shell.dart';
import 'package:nestprep/features/accounts/data/account_repository.dart';
import 'package:nestprep/features/accounts/model/account.dart';
import 'package:nestprep/features/accounts/model/auth_user.dart';
import 'package:nestprep/features/accounts/state/session_controller.dart';
import 'package:nestprep/features/household/model/household.dart';
import 'package:nestprep/features/household/state/household_controller.dart';
import 'package:nestprep/features/notifications/data/digest_prompt_store.dart';
import 'package:nestprep/features/notifications/data/notification_repository.dart';
import 'package:nestprep/features/product_analytics/state/activity_heartbeat.dart';
import 'package:nestprep/features/subscriptions/data/entitlement_repository.dart';
import 'package:nestprep/features/subscriptions/model/entitlement.dart';
import 'package:nestprep/features/welcome_tour/model/tour_target.dart';
import 'package:nestprep/features/welcome_tour/ui/tour_anchor.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/flags/feature_flags_controller.dart';
import 'package:provider/provider.dart';

import '../support/fake_auth.dart';
import '../support/fake_family_profiles.dart';
import '../support/fake_feature_flag_source.dart';
import '../support/fake_household.dart';
import '../support/fake_notifications.dart';
import '../support/fake_product_analytics.dart';
import '../support/fake_subscriptions.dart';
import '../support/household_fixtures.dart';
import '../support/pump_screen.dart';
import '../support/pump_subscriptions.dart';
import '../support/wait_for_tour.dart';

/// The shell opening the welcome tour by itself (welcome-tour ADR-0001):
/// the decision is `WelcomeTourTrigger`'s and has its own tests; this is the
/// wiring — the household loaded, the place redirect done, the entitlement
/// and the switches answered, and only then, from Today, once.
void main() {
  late FakeHouseholdRepository households;
  late HouseholdController controller;
  late FakeAuthGateway auth;
  late FakeAccountRepository accounts;
  late SessionController session;
  late FakeEntitlementRepository entitlements;
  late GoRouter router;

  /// Opens the household at [place], signed in as Sam. Everything with a
  /// listener is made here, inside the test, so it runs in the test's zone.
  Future<void> open(
    WidgetTester tester, {
    String place = 'today',
    Entitlement? entitlement = Entitlement.free,
    bool flagsUnreadable = false,
  }) async {
    households = FakeHouseholdRepository();
    controller = HouseholdController(
      householdRepository: households,
      householdDirectory: FakeHouseholdDirectory(),
      childProfileDirectory: FakeFamilyProfileRepository(),
      householdId: Fixtures.householdId,
      viewerUid: Fixtures.samUid,
    );
    auth = FakeAuthGateway();
    accounts = FakeAccountRepository();
    session = SessionController(authGateway: auth, accountRepository: accounts);
    entitlements = FakeEntitlementRepository(initial: entitlement);
    addTearDown(() async {
      controller.dispose();
      session.dispose();
      await households.close();
      await auth.close();
      await accounts.close();
      await entitlements.close();
    });
    router = GoRouter(
      initialLocation: '/households/${Fixtures.householdId}/$place',
      routes: [
        ShellRoute(
          builder: (context, state, child) =>
              ChangeNotifierProvider<HouseholdController>.value(
                value: controller,
                child: HouseholdShell(location: state.uri.path, child: child),
              ),
          routes: [
            GoRoute(
              path: '/households/:householdId/:place',
              builder: (context, state) => Column(
                children: [
                  Text('on ${state.pathParameters['place']}'),
                  const TourAnchor(
                    target: TourTarget.tabBar,
                    child: SizedBox(height: 60, width: 300),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await pumpRouter(
      tester,
      router: router,
      providers: [
        ChangeNotifierProvider<SessionController>.value(value: session),
        Provider<AccountRepository>.value(value: accounts),
        ChangeNotifierProvider(
          create: (_) {
            if (!flagsUnreadable) return testFlagsController(TestFlags.on);
            final source = FakeFeatureFlagSource();
            final controller = FeatureFlagsController(source: source);
            source.fail(StateError('permission denied'));
            return controller;
          },
        ),
        Provider<NotificationRepository>.value(
          value: FakeNotificationRepository(),
        ),
        Provider<DigestPromptStore>.value(value: FakeDigestPromptStore()),
        Provider<ActivityHeartbeat>(
          create: (_) =>
              ActivityHeartbeat(activityRecorder: FakeActivityRecorder()),
        ),
        ...SubscriptionHarness().providers,
        Provider<EntitlementRepository>.value(value: entitlements),
      ],
    );
    auth.emit(const AuthUser(uid: Fixtures.samUid, email: 'sam@nestprep.test'));
    // The shell is loading the household, which never settles.
    await tester.pump();
    await tester.pump();
  }

  /// The account document as the session hears it.
  Future<void> account(WidgetTester tester, {required bool seenTour}) async {
    accounts.emit(
      const Account(
        id: Fixtures.samUid,
        displayName: 'Sam Parent',
        householdIds: [Fixtures.householdId],
        activeHouseholdId: Fixtures.householdId,
      ),
      seenTour: seenTour,
    );
    await tester.pump();
    await tester.pump();
  }

  Future<void> household(WidgetTester tester, {Household? household}) async {
    households
      ..emitHousehold(household ?? Fixtures.household())
      ..emitMembers([Fixtures.sam]);
    await waitForTour(tester);
  }

  final tourShowing = find.text(
    TourCopy.title(TourTarget.tabBar, isLookOnly: false),
  );

  testWidgets('a newcomer on Today is taken into the tour', (tester) async {
    await open(tester);
    await account(tester, seenTour: false);
    await household(tester);

    expect(tourShowing, findsOneWidget);
  });

  testWidgets('somebody who has seen it stays on Today', (tester) async {
    await open(tester);
    await account(tester, seenTour: true);
    await household(tester);

    expect(find.text('on today'), findsOneWidget);
    expect(tourShowing, findsNothing);
  });

  testWidgets('nobody is taken out of another place into it', (tester) async {
    await open(tester, place: 'week');
    await account(tester, seenTour: false);
    await household(tester);

    expect(find.text('on week'), findsOneWidget);
    expect(tourShowing, findsNothing);
  });

  testWidgets('it waits for the entitlement, then opens', (tester) async {
    await open(tester, entitlement: null);
    await account(tester, seenTour: false);
    await household(tester);
    expect(tourShowing, findsNothing);

    entitlements.emit(Entitlement(premiumUntil: DateTime.utc(2100)));
    await waitForTour(tester);
    expect(tourShowing, findsOneWidget);
  });

  testWidgets('an unreadable switch document does not hold it back — the '
      'defaults stand', (tester) async {
    await open(tester, flagsUnreadable: true);
    await account(tester, seenTour: false);
    await household(tester);

    expect(tourShowing, findsOneWidget);
  });

  testWidgets('a new admin does the invite step first', (tester) async {
    await open(tester);
    await account(tester, seenTour: false);
    await household(
      tester,
      household: Fixtures.household().copyWith(
        pendingSetupStep: Household.invitePeopleStep,
      ),
    );

    expect(find.text('on setup'), findsOneWidget);
    expect(tourShowing, findsNothing);
  });

  testWidgets('it opens once per shell, whatever the account says after', (
    tester,
  ) async {
    await open(tester);
    await account(tester, seenTour: false);
    await household(tester);
    expect(tourShowing, findsOneWidget);

    // Skipped before the account write has come back.
    await tester.tap(find.byKey(const ValueKey('tour-skip')));
    await waitForTour(tester);
    expect(find.text('on today'), findsOneWidget);
    expect(tourShowing, findsNothing);
    expect(accounts.seenTours, isNotEmpty);
  });
}
