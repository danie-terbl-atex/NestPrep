import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/calendar/model/household_event.dart';
import 'package:nestprep/features/calendar/state/calendar_controller.dart';
import 'package:nestprep/features/groceries/model/grocery_item.dart';
import 'package:nestprep/features/groceries/state/grocery_list_controller.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pick.dart';
import 'package:nestprep/features/lunch_box/model/lunch_plan.dart';
import 'package:nestprep/features/lunch_box/model/lunch_seed_catalogue.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/today/ui/today_screen.dart';
import 'package:nestprep/features/todos/model/task.dart';
import 'package:nestprep/features/todos/state/todo_controller.dart';
import 'package:nestprep/shared/time/household_clock.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../test/support/fake_calendar_repository.dart';
import '../test/support/fake_calendar_sync.dart';
import '../test/support/fake_grocery_repository.dart';
import '../test/support/fake_todo_repository.dart';
import '../test/support/household_fixtures.dart';
import '../test/support/lunch_fixtures.dart';
import '../test/support/lunch_harness.dart';
import 'review_press.dart';

/// Today (design-system ADR-0009) in the design-review press, light, dark and
/// dark at 200% text. Regenerate with
///
///     flutter test tool/today_design_review_test.dart --update-goldens
void main() {
  setUpAll(() async {
    tz_data.initializeTimeZones();
    await loadEveryFont();
  });

  final library = LunchSeedCatalogue.itemsFor(Fixtures.samMemberId);
  LunchPick seed(String key) =>
      LunchPick.of(library.firstWhere((item) => item.seedKey == key));
  String at(int day, LunchSlot slot) => LunchPlan.slotKey(day, slot);
  final today = LunchFixtures.week.dayOf(2);

  Future<void> capture(
    WidgetTester tester,
    String name, {
    Brightness brightness = Brightness.light,
    double textScale = 1,
  }) async {
    final lunch = LunchHarness();
    final clock = HouseholdClock(
      'Africa/Johannesburg',
      now: () => LunchFixtures.nowUtc,
    );
    final todoRepository = FakeTodoRepository();
    final calendarRepository = FakeCalendarRepository();
    final syncRepository = FakeCalendarSyncRepository();
    final groceryRepository = FakeGroceryRepository();
    final todos = TodoController(
      todoRepository: todoRepository,
      householdClock: clock,
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
      isAdmin: true,
    );
    final calendar = CalendarController(
      calendarRepository: calendarRepository,
      calendarSyncRepository: syncRepository,
      householdClock: clock,
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
      householdMembers: const [],
    );
    final groceries = GroceryListController(
      groceryRepository: groceryRepository,
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
    );
    addTearDown(() async {
      todos.dispose();
      calendar.dispose();
      groceries.dispose();
      await lunch.close();
    });

    await captureScreen(
      tester,
      name,
      screen: TodayScreen(onSelectTab: (_) {}),
      brightness: brightness,
      textScale: textScale,
      providers: [
        ...lunch.providers,
        ChangeNotifierProvider<TodoController>.value(value: todos),
        ChangeNotifierProvider<CalendarController>.value(value: calendar),
        ChangeNotifierProvider<GroceryListController>.value(value: groceries),
      ],
      emit: () async {
        lunch.emit(
          items: library,
          plans: [
            LunchFixtures.plan(
              LunchFixtures.lwaziId,
              slots: {
                at(2, LunchSlot.main): seed('chicken-mayo'),
                at(2, LunchSlot.fruit): seed('apple'),
                at(2, LunchSlot.veg): seed('cucumber'),
                at(2, LunchSlot.snack): seed('popcorn'),
              },
            ),
          ],
        );
        calendarRepository
          ..emitEvents([
            HouseholdEvent(
              id: 'e1',
              title: 'Swimming',
              date: today,
              startMinute: 15 * 60,
              endMinute: 16 * 60,
              createdBy: Fixtures.samMemberId,
            ),
            HouseholdEvent(
              id: 'e2',
              title: 'Parents’ evening',
              date: today,
              startMinute: 18 * 60 + 30,
              endMinute: 19 * 60 + 30,
              createdBy: Fixtures.samMemberId,
            ),
          ])
          ..emitExceptions([]);
        syncRepository
          ..emitConnections([])
          ..emitSynced([]);
        todoRepository
          ..emitTasks([
            Task(
              id: 't1',
              title: 'Pack the swimming bag',
              dueDate: today,
              assigneeIds: const [Fixtures.samMemberId],
              createdBy: Fixtures.samMemberId,
            ),
            Task(
              id: 't2',
              title: 'Sign the trip form',
              dueDate: today,
              assigneeIds: const [Fixtures.samMemberId],
              createdBy: Fixtures.samMemberId,
            ),
          ])
          ..emitRoutines([])
          ..emitCompletions([]);
        groceryRepository.emitItems([
          for (final (index, name) in ['Bread', 'Milk', 'Apples'].indexed)
            GroceryItem(
              id: 'g$index',
              name: name,
              addedBy: Fixtures.samMemberId,
              addedAt: LunchFixtures.nowUtc,
            ),
        ]);
      },
    );
  }

  testWidgets('today — light', (tester) => capture(tester, 'today-light'));

  testWidgets(
    'today — dark',
    (tester) => capture(tester, 'today-dark', brightness: Brightness.dark),
  );

  testWidgets(
    'today — dark at 200% text',
    (tester) => capture(
      tester,
      'today-dark-200-percent-text',
      brightness: Brightness.dark,
      textScale: 2,
    ),
  );
}
