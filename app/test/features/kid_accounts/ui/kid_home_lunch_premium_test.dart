import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/app/kid_routes.dart';
import 'package:nestprep/features/accounts/model/auth_user.dart';
import 'package:nestprep/features/accounts/state/session_controller.dart';
import 'package:nestprep/features/chore_points/data/points_repository.dart';
import 'package:nestprep/features/chore_points/data/reward_repository.dart';
import 'package:nestprep/features/household/data/household_repository.dart';
import 'package:nestprep/features/kid_accounts/ui/kid_home_screen.dart';
import 'package:nestprep/features/kid_accounts/ui/kid_lunch_picks_card.dart';
import 'package:nestprep/features/kid_routines/data/kid_routine_repository.dart';
import 'package:nestprep/features/lunch_box/data/lunch_choices_repository.dart';
import 'package:nestprep/features/lunch_box/data/lunch_repository.dart';
import 'package:nestprep/features/lunch_box/model/lunch_choices.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pick.dart';
import 'package:nestprep/features/lunch_box/model/lunch_plan.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/lunch_box/model/lunch_week.dart';
import 'package:nestprep/features/meal_planning/data/meal_repository.dart';
import 'package:nestprep/features/meal_planning/model/week_plan.dart';
import 'package:nestprep/features/subscriptions/data/entitlement_repository.dart';
import 'package:nestprep/features/subscriptions/model/entitlement.dart';
import 'package:nestprep/features/todos/data/todo_repository.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/time/household_clock.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../../support/fake_auth.dart';
import '../../../support/fake_chore_points.dart';
import '../../../support/fake_household.dart';
import '../../../support/fake_kid_routines.dart';
import '../../../support/fake_lunch_planning.dart';
import '../../../support/fake_lunch_repository.dart';
import '../../../support/fake_meal_repository.dart';
import '../../../support/fake_subscriptions.dart';
import '../../../support/fake_todo_repository.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/kid_home_fixture.dart';
import '../../../support/lunch_fixtures.dart';
import '../../../support/pump_screen.dart';

/// Lunch boxes are Premium (subscriptions ADR-0009), on a kid device too: the
/// kid's home, as the route builds it, asks for lunch to choose only while the
/// household has Premium, and a free household's kid is shown no card for a
/// place that is locked.
void main() {
  setUpAll(tz_data.initializeTimeZones);

  late FakeHouseholdRepository households;
  late FakeTodoRepository todos;
  late FakeMealRepository meals;
  late FakeLunchRepository lunches;
  late FakeLunchChoicesRepository choices;
  late FakePointsRepository points;
  late FakeRewardRepository rewards;
  late FakeKidRoutineRepository routines;
  late FakeEntitlementRepository entitlements;
  late FakeAuthGateway auth;
  late FakeAccountRepository accounts;
  late SessionController session;

  final premium = Entitlement(
    premiumUntil: DateTime.now().add(const Duration(days: 30)),
  );

  setUp(() {
    households = FakeHouseholdRepository();
    todos = FakeTodoRepository();
    meals = FakeMealRepository();
    lunches = FakeLunchRepository();
    choices = FakeLunchChoicesRepository();
    points = FakePointsRepository();
    rewards = FakeRewardRepository();
    routines = FakeKidRoutineRepository();
    auth = FakeAuthGateway();
    accounts = FakeAccountRepository();
    session = SessionController(authGateway: auth, accountRepository: accounts);
  });

  tearDown(() async {
    session.dispose();
    await auth.close();
    await accounts.close();
    await entitlements.close();
    await households.close();
    await todos.close();
    await meals.close();
    await lunches.close();
    await choices.close();
    await points.close();
    await rewards.close();
    await routines.close();
  });

  /// Everything the home reads, and a lunch a grown-up offered on every
  /// school day of the week being planned, whoever is listening for it.
  Future<void> arrive(WidgetTester tester) async {
    final today = HouseholdClock(Fixtures.household().timeZone).today;
    final week = LunchWeek.planningFor(today);
    await tester.runAsync(() async {
      households
        ..emitMember(Fixtures.kid)
        ..emitHousehold(Fixtures.household());
      await pumpEventQueue();
      todos
        ..emitTasks(const [])
        ..emitRoutines(const [])
        ..emitCompletions(const []);
      meals
        ..emitWeek(WeekPlan(id: today.weekStart.iso))
        ..emitMeals(const []);
      lunches.emitPlan(
        LunchPlan.empty(childId: Fixtures.kidMemberId, week: week),
      );
      await pumpEventQueue();
    });
    // The card, and with it whoever asks for lunch to choose, exists only
    // once the home has loaded.
    await tester.pump();
    await tester.pump();
    await tester.runAsync(() async {
      lunches.emitPlan(
        LunchPlan.empty(childId: Fixtures.kidMemberId, week: week),
      );
      choices.emitChoices(
        LunchChoices.none(childId: Fixtures.kidMemberId, week: week).copyWith(
          options: {
            for (var day = 1; day <= LunchWeek.schoolDayCount; day++)
              LunchFixtures.key(day, LunchSlot.fruit): [
                LunchPick.of(LunchFixtures.apple),
                LunchPick.of(LunchFixtures.grapes),
              ],
          },
        ),
      );
      await pumpEventQueue();
    });
    await tester.pump();
    await tester.pump();
  }

  Future<void> openHome(WidgetTester tester, Entitlement entitlement) async {
    entitlements = FakeEntitlementRepository(initial: entitlement);
    tester.view.physicalSize = const Size(420 * 3, 3000 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      auth.emit(
        const AuthUser(
          uid: 'kid_tablet',
          email: '',
          kid: KidHomeFixture.identity,
        ),
      );
      await pumpEventQueue();
    });
    expect(session.kidIdentity, KidHomeFixture.identity);
    final router = GoRouter(
      initialLocation: KidRoute.homePath,
      routes: kidRoutes(session),
    );
    addTearDown(router.dispose);
    await pumpRouter(
      tester,
      router: router,
      providers: [
        ChangeNotifierProvider<SessionController>.value(value: session),
        Provider<HouseholdRepository>.value(value: households),
        Provider<TodoRepository>.value(value: todos),
        Provider<MealRepository>.value(value: meals),
        Provider<LunchRepository>.value(value: lunches),
        Provider<LunchChoicesRepository>.value(value: choices),
        Provider<PointsRepository>.value(value: points),
        Provider<RewardRepository>.value(value: rewards),
        Provider<KidRoutineRepository>.value(value: routines),
        Provider<EntitlementRepository>.value(value: entitlements),
      ],
    );
    await tester.pump();
    await arrive(tester);
  }

  testWidgets('a free household’s kid home listens for no lunch to choose and '
      'shows no card', (tester) async {
    await openHome(tester, Entitlement.free);

    expect(tester.takeException(), isNull);
    expect(find.byType(KidHomeScreen), findsOneWidget);
    expect(find.byType(KidLunchPicksCard), findsOneWidget);
    expect(find.text(LunchKidPicksCopy.kidCardTitle), findsNothing);
    expect(choices.watchedChoices, isEmpty);
  });

  testWidgets('a Premium household’s kid home listens once, and offers the '
      'lunch', (tester) async {
    await openHome(tester, premium);

    expect(tester.takeException(), isNull);
    expect(choices.watchedChoices, hasLength(1));
    expect(find.text(LunchKidPicksCopy.kidCardTitle), findsOneWidget);
  });

  testWidgets('when Premium lapses the card goes, and comes back with it', (
    tester,
  ) async {
    await openHome(tester, premium);
    expect(find.text(LunchKidPicksCopy.kidCardTitle), findsOneWidget);

    await tester.runAsync(() async {
      entitlements.emit(Entitlement.free);
      await pumpEventQueue();
    });
    await tester.pump();
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text(LunchKidPicksCopy.kidCardTitle), findsNothing);
    expect(choices.watchedChoices, hasLength(1));

    await tester.runAsync(() async {
      entitlements.emit(premium);
      await pumpEventQueue();
    });
    await tester.pump();
    expect(choices.watchedChoices, hasLength(2));
  });
}
