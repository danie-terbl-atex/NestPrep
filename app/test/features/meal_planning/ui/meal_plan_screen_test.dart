import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/meal_planning/model/meal.dart';
import 'package:nestprep/features/meal_planning/model/week_plan.dart';
import 'package:nestprep/features/meal_planning/state/meal_plan_controller.dart';
import 'package:nestprep/features/meal_planning/ui/meal_plan_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/time/household_clock.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../../support/fake_meal_repository.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';

final _nowUtc = DateTime.utc(2026, 9, 18, 9);

Meal meal(String name, {String id = 'm1'}) =>
    Meal.named(id: id, name: name, addedBy: Fixtures.samMemberId);

void main() {
  setUpAll(tz_data.initializeTimeZones);

  late FakeMealRepository repository;
  late MealPlanController controller;

  setUp(() {
    repository = FakeMealRepository();
    controller = MealPlanController(
      mealRepository: repository,
      householdClock: HouseholdClock('Africa/Johannesburg', now: () => _nowUtc),
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
    );
  });

  tearDown(() async {
    controller.dispose();
    await repository.close();
  });

  Future<void> pump(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    double scale = 1,
  }) => pumpScreen(
    tester,
    MealPlanScreen(onSelectTab: (_) {}),
    providers: [
      ChangeNotifierProvider<MealPlanController>.value(value: controller),
    ],
    brightness: brightness,
    textScale: scale,
  );

  Future<void> emit(
    WidgetTester tester, {
    List<Meal> meals = const [],
    WeekPlan? plan,
  }) async {
    repository.emitMeals(meals);
    repository.emitWeek(plan ?? WeekPlan.empty(controller.weekStart));
    await tester.pumpAndSettle();
  }

  testWidgets('holds the layout while it loads', (tester) async {
    await pump(tester);
    await tester.pump();
    expect(find.text(AppCopy.mealsTitle), findsOneWidget);
  });

  testWidgets('offers copying last week when nothing is planned', (
    tester,
  ) async {
    await pump(tester);
    await emit(tester);

    // The grid is still there — it is how the first meal gets planned.
    expect(find.text(AppCopy.mealsEmptyBody), findsOneWidget);
    expect(find.text(AppCopy.mealsCopyLastWeek), findsWidgets);
    expect(find.text(AppCopy.mealsNothingPlanned), findsWidgets);
  });

  testWidgets('shows human copy and a retry when the read fails', (
    tester,
  ) async {
    await pump(tester);
    repository.failMealsWith(const UnavailableFailure());
    await tester.pumpAndSettle();

    expect(
      find.text(AppCopy.failure(const UnavailableFailure())),
      findsOneWidget,
    );
    expect(find.text(AppCopy.retry), findsOneWidget);
  });

  testWidgets('shows the week with a meal in the slot it was planned for', (
    tester,
  ) async {
    await pump(tester);
    await emit(
      tester,
      meals: [meal('Spaghetti', id: 'spag')],
      plan: const WeekPlan(id: '2026-09-14', slots: {'2_dinner': 'spag'}),
    );

    expect(find.text('Spaghetti'), findsOneWidget);
    // The list builds lazily, so assert the shape of what is on screen: every
    // visible day has its three slots, and an empty one says so rather than
    // being a gap (`FE-08`).
    expect(find.text(AppCopy.mealsBreakfast), findsWidgets);
    expect(find.text(AppCopy.mealsLunch), findsWidgets);
    expect(find.text(AppCopy.mealsDinner), findsWidgets);
    expect(find.text(AppCopy.mealsNothingPlanned), findsWidgets);
  });

  testWidgets('tapping a slot offers the library and fills it', (tester) async {
    await pump(tester);
    final spaghetti = meal('Spaghetti', id: 'spag');
    repository.knownMeals.add(spaghetti);
    await emit(tester, meals: [spaghetti]);

    await tester.tap(find.text(AppCopy.mealsNothingPlanned).first);
    await tester.pumpAndSettle();

    expect(find.text(AppCopy.mealsLibrary), findsOneWidget);
    await tester.tap(find.text('Spaghetti').last);
    await tester.pumpAndSettle();

    expect(repository.writtenSlots.single.slots.values.single, 'spag');
  });

  testWidgets('typing a meal nobody has made before adds it', (tester) async {
    await pump(tester);
    await emit(tester);

    await tester.tap(find.text(AppCopy.mealsNothingPlanned).first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Lasagne');
    await tester.pumpAndSettle();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(repository.addedMeals.single, 'Lasagne');
  });

  testWidgets('copying last week fills the empty slots', (tester) async {
    repository.storedWeeks['2026-09-07'] = const WeekPlan(
      id: '2026-09-07',
      slots: {'2_dinner': 'spag'},
    );
    await pump(tester);
    await emit(tester, meals: [meal('Spaghetti', id: 'spag')]);

    await tester.tap(find.text(AppCopy.mealsCopyLastWeek).first);
    await tester.pumpAndSettle();

    expect(repository.writtenSlots.single.slots, {'2_dinner': 'spag'});
  });

  testWidgets('a refused write shows copy, never an error code', (
    tester,
  ) async {
    await pump(tester);
    await emit(tester, meals: [meal('Spaghetti', id: 'spag')]);

    repository.failWritesWith = const PermissionDeniedFailure();
    await controller.setSlot('2_dinner', 'spag');
    await tester.pumpAndSettle();

    expect(
      find.text(AppCopy.failure(const PermissionDeniedFailure())),
      findsOneWidget,
    );
    expect(find.textContaining('permission-denied'), findsNothing);
  });

  testWidgets('renders in dark and at 200% text without overflowing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await pump(tester, brightness: Brightness.dark, scale: 2);
    await emit(
      tester,
      meals: [meal('Spaghetti bolognese with garlic bread', id: 'spag')],
      plan: const WeekPlan(id: '2026-09-14', slots: {'2_dinner': 'spag'}),
    );

    expect(tester.takeException(), isNull);
  });
}
