import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/meal_planning/model/meal.dart';
import 'package:nestprep/features/meal_planning/model/week_plan.dart';
import 'package:nestprep/features/meal_planning/state/meal_plan_controller.dart';
import 'package:nestprep/features/meal_planning/ui/meal_plan_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/time/household_clock.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../support/fake_meal_repository.dart';
import '../support/household_fixtures.dart';
import '../support/pump_screen.dart';

/// The one thing meal-planning phase 1 still owed: the picker flow driven
/// through the screens.
///
/// One member types "Spaghetti" into Tuesday dinner; it joins the library. The
/// other member, whose library already has it, fills Thursday dinner by choosing
/// it — without typing a character. That second half is the point of a library,
/// and the thing a second phone was going to check by hand.

/// A Friday, so the week on screen is Monday the 14th to Sunday the 20th.
final _friday = DateTime.utc(2026, 9, 18, 9);
const _tuesday = '2026-09-15';
const _thursday = '2026-09-17';
const _tuesdayDinner = '2_dinner';
const _thursdayDinner = '4_dinner';

Meal _spaghetti({String id = 'meal-spaghetti'}) =>
    Meal.named(id: id, name: 'Spaghetti', addedBy: Fixtures.samMemberId);

void main() {
  setUpAll(tz_data.initializeTimeZones);

  late FakeMealRepository repository;

  setUp(() {
    repository = FakeMealRepository();
  });

  tearDown(() => repository.close());

  MealPlanController controllerFor(String memberId) {
    final controller = MealPlanController(
      mealRepository: repository,
      householdClock: HouseholdClock('Africa/Johannesburg', now: () => _friday),
      householdId: Fixtures.householdId,
      memberId: memberId,
    );
    addTearDown(controller.dispose);
    return controller;
  }

  Future<MealPlanController> open(
    WidgetTester tester, {
    required String memberId,
    required String viewerUid,
    List<Meal> library = const [],
    WeekPlan? plan,
  }) async {
    final controller = controllerFor(memberId);
    await pumpScreen(
      tester,
      MealPlanScreen(onSelectTab: (_) {}),
      view: Fixtures.view(viewerUid: viewerUid),
      providers: [
        ChangeNotifierProvider<MealPlanController>.value(value: controller),
      ],
    );
    repository.emitMeals(library);
    repository.emitWeek(plan ?? WeekPlan.empty(controller.weekStart));
    await tester.pumpAndSettle();
    return controller;
  }

  /// Opens one day's one slot. The week is a scrolling list, so the day is
  /// brought into view first — a tap on a card below the fold lands elsewhere.
  Future<void> openSlot(
    WidgetTester tester, {
    required String date,
    String slot = 'dinner',
  }) async {
    final target = find.descendant(
      of: find.byKey(ValueKey(date)),
      matching: find.text(AppCopy.mealSlotName(slot)),
    );
    await tester.scrollUntilVisible(target, 120);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  Finder pickerField() => find.descendant(
    of: find.ancestor(
      of: find.text(AppCopy.mealsPickTitle),
      matching: find.byType(NestTextField),
    ),
    matching: find.byType(TextField),
  );

  testWidgets('one member types Spaghetti into Tuesday dinner', (tester) async {
    await open(
      tester,
      memberId: Fixtures.samMemberId,
      viewerUid: Fixtures.samUid,
    );

    await openSlot(tester, date: _tuesday);
    expect(
      find.text(AppCopy.mealsLibrary),
      findsNothing,
      reason: 'nothing has been typed in this household yet',
    );

    await tester.enterText(pickerField(), 'Spaghetti');
    await tester.pumpAndSettle();
    await tester.tap(find.text('${AppCopy.groceriesAdd} “Spaghetti”'));
    await tester.pumpAndSettle();

    expect(repository.addedMeals, [
      'Spaghetti',
    ], reason: 'a name nobody has used joins the library');
    expect(repository.writtenSlots, hasLength(1));
    expect(repository.writtenSlots.single.monday, '2026-09-14');
    expect(repository.writtenSlots.single.slots.keys, [_tuesdayDinner]);
  });

  testWidgets(
    'the other member fills Thursday from the library, typing nothing',
    (tester) async {
      await open(
        tester,
        memberId: Fixtures.thandiMemberId,
        viewerUid: Fixtures.thandiUid,
        library: [_spaghetti()],
        plan: const WeekPlan(
          id: '2026-09-14',
          slots: {_tuesdayDinner: 'meal-spaghetti'},
        ),
      );

      await openSlot(tester, date: _thursday);

      // The library is offered without a keystroke, which is the whole point of
      // it: the second person does not retype what the first one named.
      expect(find.text(AppCopy.mealsLibrary), findsOneWidget);
      final inTheLibrary = find.descendant(
        of: find.byType(NestListRow),
        matching: find.text('Spaghetti'),
      );
      expect(inTheLibrary, findsOneWidget);

      await tester.tap(inTheLibrary);
      await tester.pumpAndSettle();

      expect(
        repository.addedMeals,
        isEmpty,
        reason: 'picking from the library writes no new meal',
      );
      expect(repository.writtenSlots, hasLength(1));
      expect(repository.writtenSlots.single.slots, {
        _thursdayDinner: 'meal-spaghetti',
      });
    },
  );

  testWidgets('typing a name the household already has reuses it', (
    tester,
  ) async {
    repository.knownMeals.add(_spaghetti());
    await open(
      tester,
      memberId: Fixtures.thandiMemberId,
      viewerUid: Fixtures.thandiUid,
      library: [_spaghetti()],
    );

    await openSlot(tester, date: _thursday);
    // Lower case and a stray space: the same meal, not a second one.
    await tester.enterText(pickerField(), ' spaghetti ');
    await tester.pumpAndSettle();

    expect(
      find.textContaining(AppCopy.groceriesAdd),
      findsNothing,
      reason: 'there is nothing to add — it offers the one already there',
    );
    await tester.tap(
      find.descendant(
        of: find.byType(NestListRow),
        matching: find.text('Spaghetti'),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.writtenSlots.single.slots, {
      _thursdayDinner: 'meal-spaghetti',
    });
  });
}
