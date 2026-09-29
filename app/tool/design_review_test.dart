import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/accounts/ui/sign_in_screen.dart';
import 'package:nestprep/features/calendar/model/household_event.dart';
import 'package:nestprep/features/calendar/state/calendar_controller.dart';
import 'package:nestprep/features/calendar/ui/calendar_screen.dart';
import 'package:nestprep/features/groceries/model/grocery_item.dart';
import 'package:nestprep/features/groceries/state/grocery_list_controller.dart';
import 'package:nestprep/features/groceries/ui/grocery_list_screen.dart';
import 'package:nestprep/features/household/state/household_gate_controller.dart';
import 'package:nestprep/features/household/ui/household_gate_screen.dart';
import 'package:nestprep/features/meal_planning/model/meal.dart';
import 'package:nestprep/features/meal_planning/model/week_plan.dart';
import 'package:nestprep/features/meal_planning/state/meal_plan_controller.dart';
import 'package:nestprep/features/meal_planning/ui/meal_plan_screen.dart';
import 'package:nestprep/features/product_analytics/state/beta_numbers_controller.dart';
import 'package:nestprep/features/product_analytics/ui/beta_numbers_screen.dart';
import 'package:nestprep/features/todos/model/routine.dart';
import 'package:nestprep/features/todos/model/task.dart';
import 'package:nestprep/features/todos/state/todo_controller.dart';
import 'package:nestprep/features/todos/ui/todo_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/recurrence/recurrence_rule.dart';
import 'package:nestprep/shared/time/calendar_date.dart';
import 'package:nestprep/shared/time/household_clock.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../test/support/fake_calendar_repository.dart';
import '../test/support/fake_calendar_sync.dart';
import '../test/support/fake_grocery_repository.dart';
import '../test/support/fake_household.dart';
import '../test/support/fake_meal_repository.dart';
import '../test/support/fake_product_analytics.dart';
import '../test/support/fake_todo_repository.dart';
import '../test/support/household_fixtures.dart';
import 'review_press.dart';

/// Not a test — a screenshot press. It renders every tab of the app with a
/// believable week of a believable household, in light and dark, and writes the
/// images to `app/design-review/`.
///
/// It exists because the last thing v1 needs is an opinion on how the app looks,
/// and this Mac cannot currently run an Android emulator. Looking at fourteen
/// PNGs is not the same as holding it, but it is enough to say whether the
/// direction is right.
///
/// Deliberately outside `test/`, so `flutter test` never runs it: these are
/// pictures to look at, not assertions to defend. Regenerate with
///
///     flutter test tool/design_review_test.dart --update-goldens
///
/// and read the diff as "the design changed", never as a failure.

/// A Friday morning, so every screen has both a today and a rest-of-week.
final _now = DateTime.utc(2026, 9, 18, 6, 30);
final _today = CalendarDate.parse('2026-09-18');

HouseholdClock get _clock =>
    HouseholdClock('Africa/Johannesburg', now: () => _now);

void main() {
  setUpAll(() async {
    tz_data.initializeTimeZones();
    await loadEveryFont();
  });

  /// The shared shutter (`review_press.dart`), named as this file always
  /// called it.
  Future<void> capture(
    WidgetTester tester,
    String name, {
    required Widget screen,
    required List<ChangeNotifierProvider<Object?>> providers,
    required Future<void> Function() emit,
    Brightness brightness = Brightness.light,
    double textScale = 1,
  }) => captureScreen(
    tester,
    name,
    screen: screen,
    providers: providers,
    emit: emit,
    brightness: brightness,
    textScale: textScale,
  );

  // ------------------------------------------------------------- the way in

  /// The two screens somebody sees before there is any data to show: the
  /// welcome, and the household they make on it. Both are choreographed, and
  /// `capture` settles before it presses the shutter, so these are the screens
  /// at rest rather than a frame of the entrance.
  Future<void> signIn(WidgetTester tester, Brightness brightness) =>
      captureScreen(
        tester,
        'sign-in-${brightness.name}',
        // It reads the session `pumpScreen` already provides, and nothing else.
        screen: const SignInScreen(),
        providers: const [],
        brightness: brightness,
        emit: () async {},
      );

  Future<void> householdGate(WidgetTester tester, Brightness brightness) async {
    final directory = FakeHouseholdDirectory();
    final controller = HouseholdGateController(
      householdDirectory: directory,
      suggestedName: 'Sam Parent',
      defaultTimeZone: 'Africa/Johannesburg',
    );
    addTearDown(controller.dispose);

    await captureScreen(
      tester,
      'household-gate-${brightness.name}',
      screen: const HouseholdGateScreen(),
      providers: [
        ChangeNotifierProvider<HouseholdGateController>.value(
          value: controller,
        ),
      ],
      brightness: brightness,
      emit: () async {},
    );
  }

  // ---------------------------------------------------------------- groceries

  Future<void> groceries(WidgetTester tester, Brightness brightness) async {
    final repository = FakeGroceryRepository();
    addTearDown(repository.close);
    final controller = GroceryListController(
      groceryRepository: repository,
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
      now: () => _now,
    );
    addTearDown(controller.dispose);

    await captureScreen(
      tester,
      'groceries-${brightness.name}',
      screen: GroceryListScreen(onSelectTab: (_) {}),
      providers: [
        ChangeNotifierProvider<GroceryListController>.value(value: controller),
      ],
      brightness: brightness,
      emit: () async {
        repository.emitItems([
          for (final (id, name, quantity) in [
            ('g1', 'Milk', '2 litres'),
            ('g2', 'Brown bread', null),
            ('g3', 'Rooibos', '80 bags'),
            ('g4', 'Bananas', 'a hand'),
            ('g5', 'Chicken thighs', '1 kg'),
          ])
            GroceryItem(
              id: id,
              name: name,
              quantity: quantity,
              addedBy: Fixtures.samMemberId,
              addedAt: _now,
            ),
          GroceryItem(
            id: 'g6',
            name: 'Eggs',
            quantity: 'a dozen',
            addedBy: Fixtures.thandiMemberId,
            addedAt: _now,
            boughtAt: _now,
            boughtBy: Fixtures.thandiMemberId,
          ),
        ]);
      },
    );
  }

  // -------------------------------------------------------------------- todos

  ({FakeTodoRepository repository, TodoController controller}) todoParts() {
    final repository = FakeTodoRepository();
    addTearDown(repository.close);
    final controller = TodoController(
      todoRepository: repository,
      householdClock: _clock,
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
      isAdmin: true,
    );
    addTearDown(controller.dispose);
    return (repository: repository, controller: controller);
  }

  Future<void> emitTodos(FakeTodoRepository repository) async {
    repository.emitRoutines([
      Routine(
        id: 'r-laundry',
        name: 'Laundry Day Tasks',
        firstDate: CalendarDate.parse('2026-09-19'),
        recurrence: const RecurrenceRule(
          frequency: RecurrenceFrequency.weekly,
          weekdays: [6],
        ),
        defaultAssigneeIds: const [Fixtures.thandiMemberId],
        createdBy: Fixtures.samMemberId,
      ),
    ]);
    repository.emitTasks([
      for (final (id, title, due, who) in [
        ('t1', 'Take the bins out', '2026-09-18', Fixtures.samMemberId),
        ('t2', 'Pack Kid\'s swimming bag', '2026-09-18', Fixtures.samMemberId),
        ('t3', 'Pay the school fees', '2026-09-16', Fixtures.samMemberId),
        ('t4', 'Water the herbs', '2026-09-18', null),
        ('t5', 'Strip the beds', '2026-09-19', Fixtures.thandiMemberId),
      ])
        Task(
          id: id,
          title: title,
          dueDate: CalendarDate.parse(due),
          assigneeIds: who == null ? const [] : [who],
          createdBy: Fixtures.samMemberId,
        ),
    ]);
    repository.emitCompletions([]);
  }

  // -------------------------------------------------------------------- week

  Future<void> week(WidgetTester tester, Brightness brightness) async {
    final repository = FakeCalendarRepository();
    addTearDown(repository.close);
    final controller = CalendarController(
      calendarRepository: repository,
      calendarSyncRepository: FakeCalendarSyncRepository(),
      householdClock: _clock,
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
      householdMembers: const [],
    );
    addTearDown(controller.dispose);

    await captureScreen(
      tester,
      'week-${brightness.name}',
      screen: CalendarScreen(onSelectTab: (_) {}),
      providers: [
        ChangeNotifierProvider<CalendarController>.value(value: controller),
      ],
      brightness: brightness,
      emit: () async {
        repository.emitEvents([
          for (final (id, title, on, start, who) in [
            ('e1', 'School run', '2026-09-18', 450, Fixtures.samMemberId),
            ('e2', 'Kid — swimming', '2026-09-18', 960, Fixtures.kidMemberId),
            (
              'e3',
              'Thandi off at 14:00',
              '2026-09-18',
              840,
              Fixtures.thandiMemberId,
            ),
            ('e4', 'Parents evening', '2026-09-18', 1080, null),
          ])
            HouseholdEvent(
              id: id,
              title: title,
              date: CalendarDate.parse(on),
              startMinute: start,
              endMinute: start + 60,
              memberIds: who == null ? const [] : [who],
              createdBy: Fixtures.samMemberId,
            ),
          HouseholdEvent(
            id: 'e5',
            title: 'Rubbish out',
            date: _today,
            recurrence: const RecurrenceRule(
              frequency: RecurrenceFrequency.weekly,
              weekdays: [4],
            ),
            createdBy: Fixtures.samMemberId,
          ),
        ]);
        repository.emitExceptions([]);
      },
    );
  }

  // -------------------------------------------------------------------- meals

  Future<void> meals(WidgetTester tester, Brightness brightness) async {
    final repository = FakeMealRepository();
    addTearDown(repository.close);
    final controller = MealPlanController(
      mealRepository: repository,
      householdClock: _clock,
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
    );
    addTearDown(controller.dispose);

    const library = [
      ('m1', 'Spaghetti bolognese'),
      ('m2', 'Chicken curry'),
      ('m3', 'Boerewors and pap'),
      ('m4', 'Toast and eggs'),
      ('m5', 'Leftovers'),
      ('m6', 'Oats'),
      ('m7', 'Sandwiches'),
    ];

    await captureScreen(
      tester,
      'meals-${brightness.name}',
      screen: MealPlanScreen(onSelectTab: (_) {}),
      providers: [
        ChangeNotifierProvider<MealPlanController>.value(value: controller),
      ],
      brightness: brightness,
      emit: () async {
        repository.emitMeals([
          for (final (id, name) in library)
            Meal.named(id: id, name: name, addedBy: Fixtures.samMemberId),
        ]);
        repository.emitWeek(
          WeekPlan(
            id: controller.weekStart.iso,
            slots: const {
              '1_breakfast': 'm6',
              '1_dinner': 'm2',
              '2_breakfast': 'm4',
              '2_lunch': 'm7',
              '2_dinner': 'm1',
              '3_dinner': 'm5',
              '4_breakfast': 'm6',
              '4_dinner': 'm3',
              '5_dinner': 'm1',
            },
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------------ the set

  for (final brightness in Brightness.values) {
    testWidgets('week — ${brightness.name}', (tester) async {
      await week(tester, brightness);
    });

    testWidgets('todos, mine today — ${brightness.name}', (tester) async {
      final parts = todoParts();
      await captureScreen(
        tester,
        'todos-mine-${brightness.name}',
        screen: TodoScreen(onSelectTab: (_) {}),
        providers: [
          ChangeNotifierProvider<TodoController>.value(value: parts.controller),
        ],
        brightness: brightness,
        emit: () => emitTodos(parts.repository),
      );
    });

    testWidgets('todos, the whole household — ${brightness.name}', (
      tester,
    ) async {
      final parts = todoParts();
      await captureScreen(
        tester,
        'todos-everyone-${brightness.name}',
        screen: TodoScreen(onSelectTab: (_) {}),
        providers: [
          ChangeNotifierProvider<TodoController>.value(value: parts.controller),
        ],
        brightness: brightness,
        emit: () async {
          await emitTodos(parts.repository);
          await tester.pumpAndSettle();
          await tester.tap(find.text(AppCopy.todosEveryone));
        },
      );
    });

    testWidgets('sign in — ${brightness.name}', (tester) async {
      await signIn(tester, brightness);
    });

    testWidgets('household gate — ${brightness.name}', (tester) async {
      await householdGate(tester, brightness);
    });

    testWidgets('groceries — ${brightness.name}', (tester) async {
      await groceries(tester, brightness);
    });

    testWidgets('meals — ${brightness.name}', (tester) async {
      await meals(tester, brightness);
    });

    // Daniel's readout during the beta (product-analytics ADR-0001): a week
    // three weeks into it, with this week's invite cohort still counting.
    testWidgets('beta numbers — ${brightness.name}', (tester) async {
      final repository = FakeBetaNumbersRepository(isReader: true);
      addTearDown(repository.close);
      final controller = BetaNumbersController(
        betaNumbersRepository: repository,
        now: () => _now,
      );
      addTearDown(controller.dispose);
      await capture(
        tester,
        'beta-numbers-${brightness.name}',
        screen: const BetaNumbersScreen(),
        providers: [
          ChangeNotifierProvider<BetaNumbersController>.value(
            value: controller,
          ),
        ],
        brightness: brightness,
        emit: () async => repository.emitWeeks([
          weekOf(
            '2026-W38',
            CalendarDate.parse('2026-09-14'),
            activeFamilies: 23,
            familiesSeen: 38,
            lunchPlansCreated: 61,
            familiesPlanningLunches: 27,
            newFamilies: 9,
            newFamiliesInvitingAnAdult: 5,
            computedAt: _now,
          ),
          weekOf(
            '2026-W37',
            CalendarDate.parse('2026-09-07'),
            activeFamilies: 17,
            familiesSeen: 31,
            lunchPlansCreated: 44,
            familiesPlanningLunches: 21,
            newFamilies: 14,
            newFamiliesInvitingAnAdult: 8,
          ),
          weekOf(
            '2026-W36',
            CalendarDate.parse('2026-08-31'),
            activeFamilies: 9,
            familiesSeen: 20,
            lunchPlansCreated: 18,
            familiesPlanningLunches: 11,
            newFamilies: 20,
            newFamiliesInvitingAnAdult: 9,
            isInviteCohortComplete: true,
          ),
        ]),
      );
    });
  }

  // The accessibility claim the phase notes make, as a picture.
  testWidgets('the week in dark at 200% text', (tester) async {
    final repository = FakeCalendarRepository();
    addTearDown(repository.close);
    final controller = CalendarController(
      calendarRepository: repository,
      calendarSyncRepository: FakeCalendarSyncRepository(),
      householdClock: _clock,
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
      householdMembers: const [],
    );
    addTearDown(controller.dispose);

    await captureScreen(
      tester,
      'week-dark-200-percent-text',
      screen: CalendarScreen(onSelectTab: (_) {}),
      providers: [
        ChangeNotifierProvider<CalendarController>.value(value: controller),
      ],
      brightness: Brightness.dark,
      textScale: 2,
      emit: () async {
        repository.emitEvents([
          HouseholdEvent(
            id: 'e1',
            title: 'School run',
            date: _today,
            startMinute: 450,
            endMinute: 510,
            createdBy: Fixtures.samMemberId,
          ),
        ]);
        repository.emitExceptions([]);
      },
    );
  });
}
