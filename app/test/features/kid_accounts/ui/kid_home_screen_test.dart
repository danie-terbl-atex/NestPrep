import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/accounts/model/auth_user.dart';
import 'package:nestprep/features/accounts/state/session_controller.dart';
import 'package:nestprep/features/household/model/access_defaults.dart';
import 'package:nestprep/features/household/model/access_level.dart';
import 'package:nestprep/features/household/model/household_area.dart';
import 'package:nestprep/features/kid_accounts/state/kid_home_controller.dart';
import 'package:nestprep/features/kid_accounts/ui/kid_home_screen.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pick.dart';
import 'package:nestprep/features/meal_planning/model/week_plan.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/kid_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../../support/fake_auth.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/kid_home_fixture.dart';
import '../../../support/pump_screen.dart';

/// The one screen a kid device has (accounts ADR-0003), in all four states and
/// the fifth that is not an error: a grown-up signed this device out.
void main() {
  setUpAll(tz_data.initializeTimeZones);

  late KidHomeFixture fixture;

  setUp(() => fixture = KidHomeFixture());
  tearDown(() => fixture.close());

  Future<void> pump(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    double scale = 1,
    SessionController? session,
  }) => pumpScreen(
    tester,
    const KidHomeScreen(),
    providers: [
      ChangeNotifierProvider<KidHomeController>.value(
        value: fixture.controller,
      ),
      if (session != null)
        ChangeNotifierProvider<SessionController>.value(value: session),
    ],
    brightness: brightness,
    textScale: scale,
  );

  final lunch = {
    WeekPlan.slotKey(KidHomeFixture.today.weekday, MealSlot.lunch): 'pasta',
  };

  testWidgets('holds the layout while it loads', (tester) async {
    await pump(tester);
    await tester.pump();
    expect(find.byKey(const ValueKey('loading')), findsOneWidget);
    expect(find.text(KidCopy.homeTitle), findsOneWidget);
  });

  testWidgets('greets the kid by name, with their jobs and their food', (
    tester,
  ) async {
    await pump(tester);
    await tester.runAsync(
      () => fixture.arrive(
        tasks: [
          KidHomeFixture.chore('bed', 'Make your bed'),
          KidHomeFixture.chore('teeth', 'Brush teeth'),
        ],
        completions: [KidHomeFixture.done('bed')],
        slots: lunch,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(KidCopy.greeting('Kid')), findsOne);
    expect(find.text(KidCopy.choresProgress(1, 2)), findsOneWidget);
    expect(find.text('Make your bed'), findsOneWidget);
    expect(find.text('Brush teeth'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Pasta bake'), 200);
    expect(find.text('Pasta bake'), findsOneWidget);
    expect(find.text(KidCopy.foodNothingPlanned), findsNWidgets(2));
  });

  testWidgets('a tap anywhere on a job ticks it off', (tester) async {
    await pump(tester);
    await tester.runAsync(
      () => fixture.arrive(tasks: [KidHomeFixture.chore('bed', 'Make it')]),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(KidCopy.choreTapToFinish));
    await tester.pumpAndSettle();

    expect(fixture.todos.completed.single.taskId, 'bed');
  });

  testWidgets('a day with no jobs says so, and still shows the food', (
    tester,
  ) async {
    await pump(tester);
    await tester.runAsync(() => fixture.arrive(slots: lunch));
    await tester.pumpAndSettle();

    expect(find.text(KidCopy.choresNone), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Pasta bake'), 200);
    expect(find.text(KidCopy.foodTitle), findsOneWidget);
  });

  // lunch-box ADR-0004: the kid sees the box a grown-up packed for today.
  testWidgets('shows their own lunch box, drawn and named', (tester) async {
    await pump(tester);
    await tester.runAsync(
      () => fixture.arrive(
        lunchSlots: const {
          '2_main': LunchPick(itemId: 'wrap', name: 'Chicken wrap'),
          '2_fruit': LunchPick(itemId: 'apple', name: 'Apple slices'),
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Apple slices'), 200);
    expect(find.text(LunchCopy.kidLunchTitle), findsOneWidget);
    expect(find.text('Chicken wrap'), findsOneWidget);
  });

  testWidgets('an empty lunch box says a grown-up has not packed it yet', (
    tester,
  ) async {
    await pump(tester);
    await tester.runAsync(fixture.arrive);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text(LunchCopy.kidLunchNothing), 200);
    expect(find.text(LunchCopy.kidLunchNothing), findsOneWidget);
  });

  testWidgets('every job done is a celebration', (tester) async {
    await pump(tester);
    await tester.runAsync(
      () => fixture.arrive(
        tasks: [KidHomeFixture.chore('bed', 'Make your bed')],
        completions: [KidHomeFixture.done('bed')],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(KidCopy.choresAllDone), findsOneWidget);
    expect(find.text(KidCopy.choreDone), findsOneWidget);
  });

  testWidgets('an error offers a retry, in words', (tester) async {
    await pump(tester);
    fixture.households.failHouseholdWith(const UnavailableFailure());
    await tester.pumpAndSettle();

    expect(find.text(AppCopy.failure(const UnavailableFailure())), findsOne);
    expect(find.text(AppCopy.retry), findsOneWidget);
  });

  testWidgets('a device a grown-up signed out says so and goes back to the '
      'start', (tester) async {
    final auth = FakeAuthGateway();
    final session = SessionController(
      authGateway: auth,
      accountRepository: FakeAccountRepository(),
    );
    addTearDown(() async {
      session.dispose();
      await auth.close();
    });
    auth.emit(const AuthUser(uid: 'kid_tablet', email: ''));

    await pump(tester, session: session);
    fixture.households.emitMember(null);
    await tester.pumpAndSettle();

    expect(find.text(KidCopy.disconnectedTitle), findsOneWidget);
    expect(find.text(AppCopy.retry), findsNothing);
    await tester.tap(find.text(KidCopy.disconnectedAction));
    await tester.pumpAndSettle();
    expect(auth.signOutCount, 1);
  });

  testWidgets('signing out asks first, and staying is the easy answer', (
    tester,
  ) async {
    await pump(tester);
    await tester.runAsync(fixture.arrive);
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel(KidCopy.signOut));
    await tester.pumpAndSettle();

    expect(find.text(KidCopy.signOutConfirm), findsOneWidget);
    await tester.tap(find.text(KidCopy.signOutCancel));
    await tester.pumpAndSettle();
    expect(find.text(KidCopy.signOutConfirm), findsNothing);
  });

  testWidgets('survives dark at 200% text on a 360-wide phone', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await pump(tester, brightness: Brightness.dark, scale: 2);
    await tester.runAsync(
      () => fixture.arrive(
        tasks: [
          KidHomeFixture.chore('bed', 'Make your bed before school starts'),
          KidHomeFixture.chore('teeth', 'Brush teeth'),
        ],
        completions: [KidHomeFixture.done('teeth')],
        slots: lunch,
        lunchSlots: const {
          '2_main': LunchPick(itemId: 'wrap', name: 'Chicken mayo wrap'),
          '2_treat': LunchPick(itemId: 'muffin', name: 'Banana muffin'),
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(find.text('Banana muffin'), 200);
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(find.text('Pasta bake'), 200);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a grant that only looks shows the jobs without a tap', (
    tester,
  ) async {
    await pump(tester);
    await tester.runAsync(
      () => fixture.arrive(tasks: [KidHomeFixture.chore('dishes', 'Dishes')]),
    );
    fixture.households.emitMember(
      Fixtures.kid.copyWith(
        access: AccessDefaults.kid.withLevel(
          HouseholdArea.todos,
          AccessLevel.view,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dishes'), findsOneWidget);
    expect(find.text(KidCopy.choreToDo), findsOneWidget);
    expect(find.text(KidCopy.choreTapToFinish), findsNothing);
  });

  testWidgets('a grant that opens nothing says so, kindly', (tester) async {
    await pump(tester);
    await tester.runAsync(fixture.arrive);
    fixture.households.emitMember(Fixtures.kid.copyWith(access: null));
    await tester.pumpAndSettle();

    expect(find.text(KidCopy.nothingShownTitle), findsOneWidget);
    expect(find.text(KidCopy.choresTitle), findsNothing);
    expect(find.text(KidCopy.foodTitle), findsNothing);
  });
}
