import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/calendar/model/household_event.dart';
import 'package:nestprep/features/calendar/state/calendar_controller.dart';
import 'package:nestprep/features/calendar/ui/calendar_screen.dart';
import 'package:nestprep/features/groceries/model/grocery_item.dart';
import 'package:nestprep/features/groceries/state/grocery_list_controller.dart';
import 'package:nestprep/features/groceries/ui/grocery_list_screen.dart';
import 'package:nestprep/features/meal_planning/model/meal.dart';
import 'package:nestprep/features/meal_planning/model/week_plan.dart';
import 'package:nestprep/features/meal_planning/state/meal_plan_controller.dart';
import 'package:nestprep/features/meal_planning/ui/meal_plan_screen.dart';
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
import '../test/support/fake_grocery_repository.dart';
import '../test/support/fake_meal_repository.dart';
import '../test/support/fake_todo_repository.dart';
import '../test/support/household_fixtures.dart';
import '../test/support/pump_screen.dart';

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

const _phone = Size(390, 844);

HouseholdClock get _clock =>
    HouseholdClock('Africa/Johannesburg', now: () => _now);

/// Every font the app ships, read from the bundle's own manifest — the type
/// family *and* the icon font. A test renders in Ahem by default, so without
/// this the screenshots are black boxes where the words and the icons should be,
/// which is the opposite of useful for a design review.
Future<void> _loadEveryFont() async {
  final manifest = json.decode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<Object?>;
  for (final entry in manifest.cast<Map<String, Object?>>()) {
    final family = entry['family'] as String?;
    final assets = (entry['fonts'] as List<Object?>? ?? const [])
        .cast<Map<String, Object?>>();
    if (family == null || assets.isEmpty) continue;
    final loader = FontLoader(family);
    for (final asset in assets) {
      final path = asset['asset'] as String?;
      if (path != null) loader.addFont(rootBundle.load(path));
    }
    // A family the bundle names but does not carry — cupertino_icons is one —
    // must not take the whole press down with it.
    try {
      await loader.load();
    } on Exception {
      continue;
    }
  }
}

void main() {
  setUpAll(() async {
    tz_data.initializeTimeZones();
    await _loadEveryFont();
  });

  /// Renders one screen at phone size and writes it to `design-review/`.
  Future<void> capture(
    WidgetTester tester,
    String name, {
    required Widget screen,
    required List<ChangeNotifierProvider<Object?>> providers,
    required Future<void> Function() emit,
    Brightness brightness = Brightness.light,
    double textScale = 1,
  }) async {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = _phone * 2;
    addTearDown(tester.view.reset);
    // Elevation is part of the look being reviewed; tests normally hide it. It
    // has to go back before the test ends, or the framework's painting-invariant
    // check fails the test it was meant to illustrate.
    debugDisableShadows = false;

    await pumpScreen(
      tester,
      screen,
      providers: providers,
      brightness: brightness,
      textScale: textScale,
    );
    await emit();
    await tester.pumpAndSettle();

    try {
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('../design-review/$name.png'),
      );
    } finally {
      debugDisableShadows = true;
    }
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

    await capture(
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
      householdClock: _clock,
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
      householdMembers: const [],
    );
    addTearDown(controller.dispose);

    await capture(
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

    await capture(
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
      await capture(
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
      await capture(
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

    testWidgets('groceries — ${brightness.name}', (tester) async {
      await groceries(tester, brightness);
    });

    testWidgets('meals — ${brightness.name}', (tester) async {
      await meals(tester, brightness);
    });
  }

  // The accessibility claim the phase notes make, as a picture.
  testWidgets('the week in dark at 200% text', (tester) async {
    final repository = FakeCalendarRepository();
    addTearDown(repository.close);
    final controller = CalendarController(
      calendarRepository: repository,
      householdClock: _clock,
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
      householdMembers: const [],
    );
    addTearDown(controller.dispose);

    await capture(
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
