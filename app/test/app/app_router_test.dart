import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/app/app_router.dart';
import 'package:nestprep/app/family_route.dart';
import 'package:nestprep/app/household_route.dart';
import 'package:nestprep/app/household_shell.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/accounts/model/account.dart';
import 'package:nestprep/features/accounts/model/auth_user.dart';
import 'package:nestprep/features/accounts/state/session_controller.dart';
import 'package:nestprep/features/accounts/ui/sign_in_screen.dart';
import 'package:nestprep/features/calendar/data/calendar_repository.dart';
import 'package:nestprep/features/calendar/ui/calendar_screen.dart';
import 'package:nestprep/features/calendar_sync/data/calendar_sync_directory.dart';
import 'package:nestprep/features/calendar_sync/data/calendar_sync_repository.dart';
import 'package:nestprep/features/family_profiles/data/child_profile_directory.dart';
import 'package:nestprep/features/family_profiles/data/family_profile_repository.dart';
import 'package:nestprep/features/family_profiles/ui/family_member_screen.dart';
import 'package:nestprep/features/family_profiles/ui/family_screen.dart';
import 'package:nestprep/features/groceries/data/grocery_repository.dart';
import 'package:nestprep/features/groceries/ui/grocery_list_screen.dart';
import 'package:nestprep/features/household/data/household_directory.dart';
import 'package:nestprep/features/household/data/household_repository.dart';
import 'package:nestprep/features/household/ui/household_screen.dart';
import 'package:nestprep/features/meal_planning/data/meal_repository.dart';
import 'package:nestprep/features/meal_planning/ui/meal_plan_screen.dart';
import 'package:nestprep/features/product_analytics/data/beta_numbers_repository.dart';
import 'package:nestprep/features/product_analytics/state/activity_heartbeat.dart';
import 'package:nestprep/features/product_analytics/ui/beta_numbers_screen.dart';
import 'package:nestprep/features/todos/data/todo_repository.dart';
import 'package:nestprep/features/todos/ui/todo_screen.dart';
import 'package:nestprep/shared/links/external_link_opener.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../support/fake_auth.dart';
import '../support/fake_calendar_repository.dart';
import '../support/fake_calendar_sync.dart';
import '../support/fake_family_profiles.dart';
import '../support/fake_grocery_repository.dart';
import '../support/fake_household.dart';
import '../support/fake_link_opener.dart';
import '../support/fake_meal_repository.dart';
import '../support/fake_product_analytics.dart';
import '../support/fake_todo_repository.dart';
import '../support/household_fixtures.dart';
import '../support/pump_subscriptions.dart';

/// The wiring every screen arrives through.
///
/// `redirectForSession` decides *where* somebody goes and has its own tests.
/// This is the other half: that each route can actually build its screen. A
/// controller asking for a repository nobody registered compiles, analyses and
/// ships, and then throws a ProviderNotFoundException the first time anybody
/// opens that tab — on a real phone, in front of a household.
void main() {
  setUpAll(tz_data.initializeTimeZones);

  late FakeAuthGateway auth;
  late FakeAccountRepository accounts;
  late SessionController session;
  late FakeHouseholdRepository households;
  late FakeHouseholdDirectory directory;
  late FakeCalendarRepository calendar;
  late FakeTodoRepository todos;
  late FakeMealRepository meals;
  late FakeGroceryRepository groceries;
  late FakeActivityRecorder activity;
  late FakeBetaNumbersRepository betaNumbers;
  late FakeFamilyProfileRepository familyProfiles;

  setUp(() {
    activity = FakeActivityRecorder();
    betaNumbers = FakeBetaNumbersRepository(isReader: true);
    auth = FakeAuthGateway();
    accounts = FakeAccountRepository();
    session = SessionController(authGateway: auth, accountRepository: accounts);
    households = FakeHouseholdRepository();
    directory = FakeHouseholdDirectory();
    calendar = FakeCalendarRepository();
    todos = FakeTodoRepository();
    meals = FakeMealRepository();
    groceries = FakeGroceryRepository();
    familyProfiles = FakeFamilyProfileRepository();
  });

  tearDown(() async {
    session.dispose();
    await auth.close();
    await accounts.close();
    await households.close();
    await calendar.close();
    await todos.close();
    await meals.close();
    await groceries.close();
    await betaNumbers.close();
    await familyProfiles.close();
  });

  late GoRouter router;

  Future<void> pumpApp(WidgetTester tester) async {
    router = createAppRouter(session);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<HouseholdRepository>.value(value: households),
          Provider<HouseholdDirectory>.value(value: directory),
          Provider<CalendarRepository>.value(value: calendar),
          Provider<CalendarSyncRepository>.value(
            value: FakeCalendarSyncRepository(),
          ),
          Provider<CalendarSyncDirectory>.value(
            value: FakeCalendarSyncDirectory(),
          ),
          Provider<ExternalLinkOpener>.value(value: FakeLinkOpener()),
          Provider<TodoRepository>.value(value: todos),
          Provider<MealRepository>.value(value: meals),
          Provider<GroceryRepository>.value(value: groceries),
          Provider<ActivityHeartbeat>(
            create: (_) => ActivityHeartbeat(activityRecorder: activity),
          ),
          Provider<BetaNumbersRepository>.value(value: betaNumbers),
          Provider<FamilyProfileRepository>.value(value: familyProfiles),
          // Marking a child is the `setChildProfile` callable
          // (subscriptions ADR-0001); the fake answers for both.
          Provider<ChildProfileDirectory>.value(value: familyProfiles),
          // The store, premium and the shell's entitlement listener.
          ...SubscriptionHarness().providers,
          ChangeNotifierProvider<SessionController>.value(value: session),
        ],
        child: MaterialApp.router(
          theme: nestThemeData(NestTheme.light()),
          routerConfig: router,
        ),
      ),
    );
  }

  /// The session and its account arrive over real futures, which pumping
  /// frames cannot advance.
  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  /// Signs in and hands the household shell everything it reads, so a tab can
  /// build.
  Future<void> signInWithAHousehold(WidgetTester tester) async {
    auth.emit(const AuthUser(uid: Fixtures.samUid, email: 'sam@nestprep.test'));
    await settle(tester);
    accounts.emit(
      const Account(
        id: Fixtures.samUid,
        displayName: 'Sam Parent',
        householdIds: [Fixtures.householdId],
        activeHouseholdId: Fixtures.householdId,
      ),
    );
    await settle(tester);
    households.emitHousehold(Fixtures.household());
    households.emitMembers([Fixtures.sam, Fixtures.thandi, Fixtures.kid]);
    await settle(tester);
  }

  testWidgets('signed out, the app lands on the way in', (tester) async {
    await pumpApp(tester);
    auth.emit(null);
    await settle(tester);

    expect(find.byType(SignInScreen), findsOneWidget);
  });

  group('every tab builds, with the controller it asks for', () {
    for (final (tab, screen) in [
      (HouseholdTab.week, CalendarScreen),
      (HouseholdTab.todos, TodoScreen),
      (HouseholdTab.groceries, GroceryListScreen),
      (HouseholdTab.meals, MealPlanScreen),
    ]) {
      testWidgets(tab.name, (tester) async {
        await pumpApp(tester);
        await signInWithAHousehold(tester);

        router.go(HouseholdRoute.pathFor(Fixtures.householdId, tab));
        await settle(tester);

        expect(
          tester.takeException(),
          isNull,
          reason: 'a repository nobody registered throws here and nowhere else',
        );
        expect(find.byType(screen), findsOneWidget);
      });
    }
  });

  testWidgets('and so does the household screen under the shell', (
    tester,
  ) async {
    await pumpApp(tester);
    await signInWithAHousehold(tester);

    router.go(
      HouseholdRoute.pathFor(
        Fixtures.householdId,
        HouseholdTab.week,
      ).replaceAll(HouseholdTab.week.segment, 'household'),
    );
    await settle(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(HouseholdScreen), findsOneWidget);
  });

  testWidgets('opening a household counts it as used today', (tester) async {
    await pumpApp(tester);
    await signInWithAHousehold(tester);
    router.go(HouseholdRoute.pathFor(Fixtures.householdId, HouseholdTab.week));
    await settle(tester);

    expect(activity.recorded, [Fixtures.householdId]);
  });

  testWidgets(
    'the Beta numbers screen builds, with the controller it asks for',
    (tester) async {
      await pumpApp(tester);
      await signInWithAHousehold(tester);

      router.go(BetaNumbersScreen.path);
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(BetaNumbersScreen), findsOneWidget);
    },
  );

  // family-profiles: the family and a profile under their own shell.
  testWidgets('the family and a profile build, with both controllers', (
    tester,
  ) async {
    await pumpApp(tester);
    await signInWithAHousehold(tester);

    router.go(FamilyRoute.pathFor(Fixtures.householdId));
    await settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.byType(FamilyScreen), findsOneWidget);

    router.go(
      FamilyRoute.memberPathFor(Fixtures.householdId, Fixtures.kidMemberId),
    );
    await settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.byType(FamilyMemberScreen), findsOneWidget);
    expect(familyProfiles.healthWatched, [
      Fixtures.kidMemberId,
    ], reason: 'an admin reads the medication of the person the route names');
  });
}
