import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/calendar/state/calendar_controller.dart';
import 'package:nestprep/features/family_profiles/model/family_roster.dart';
import 'package:nestprep/features/groceries/state/grocery_list_controller.dart';
import 'package:nestprep/features/household/model/access_grant.dart';
import 'package:nestprep/features/household/model/access_level.dart';
import 'package:nestprep/features/household/model/household_area.dart';
import 'package:nestprep/features/today/ui/today_screen.dart';
import 'package:nestprep/features/todos/state/todo_controller.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/time/household_clock.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_calendar_repository.dart';
import '../../../support/fake_calendar_sync.dart';
import '../../../support/fake_grocery_repository.dart';
import '../../../support/fake_todo_repository.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/lunch_fixtures.dart';
import '../../../support/lunch_harness.dart';
import '../../../support/pump_screen.dart';

/// Today (design-system ADR-0009): the day at a glance, made of the same
/// controllers its tabs use, showing only what the grant opens.
void main() {
  late LunchHarness lunch;
  late FakeTodoRepository todoRepository;
  late FakeCalendarRepository calendarRepository;
  late FakeCalendarSyncRepository syncRepository;
  late FakeGroceryRepository groceryRepository;
  late TodoController todos;
  late CalendarController calendar;
  late GroceryListController groceries;

  setUp(() {
    lunch = LunchHarness();
    final clock = HouseholdClock(
      'Africa/Johannesburg',
      now: () => LunchFixtures.nowUtc,
    );
    todoRepository = FakeTodoRepository();
    calendarRepository = FakeCalendarRepository();
    syncRepository = FakeCalendarSyncRepository();
    groceryRepository = FakeGroceryRepository();
    todos = TodoController(
      todoRepository: todoRepository,
      householdClock: clock,
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
      isAdmin: true,
    );
    calendar = CalendarController(
      calendarRepository: calendarRepository,
      calendarSyncRepository: syncRepository,
      householdClock: clock,
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
      householdMembers: const [],
    );
    groceries = GroceryListController(
      groceryRepository: groceryRepository,
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
    );
  });

  tearDown(() async {
    todos.dispose();
    calendar.dispose();
    groceries.dispose();
    await lunch.close();
  });

  Future<void> pumpFamily(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    double textScale = 1,
    FamilyRoster? roster,
  }) async {
    await pumpScreen(
      tester,
      TodayScreen(onSelectTab: (_) {}),
      view: Fixtures.view(),
      brightness: brightness,
      textScale: textScale,
      providers: [
        ...lunch.providers,
        ChangeNotifierProvider<TodoController>.value(value: todos),
        ChangeNotifierProvider<CalendarController>.value(value: calendar),
        ChangeNotifierProvider<GroceryListController>.value(value: groceries),
      ],
    );
    lunch.emit(roster: roster);
    todoRepository
      ..emitTasks([])
      ..emitRoutines([])
      ..emitCompletions([]);
    calendarRepository
      ..emitEvents([])
      ..emitExceptions([]);
    syncRepository
      ..emitConnections([])
      ..emitSynced([]);
    groceryRepository.emitItems([]);
    await tester.pumpAndSettle();
  }

  testWidgets('family sees each of the day’s places', (tester) async {
    await pumpFamily(tester);

    for (final eyebrow in [
      TodayCopy.lunchEyebrow,
      TodayCopy.agendaEyebrow,
      TodayCopy.todoEyebrow,
    ]) {
      await tester.scrollUntilVisible(
        find.text(eyebrow.toUpperCase()),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(eyebrow.toUpperCase()), findsOneWidget, reason: eyebrow);
    }
    expect(find.text(TodayCopy.agendaEmpty), findsOneWidget);
    expect(find.text(TodayCopy.todoDone), findsOneWidget);
  });

  testWidgets('with nobody to pack for, it asks who to add first', (
    tester,
  ) async {
    await pumpFamily(
      tester,
      roster: FamilyRoster(
        members: [Fixtures.sam],
        profiles: const [],
        schools: const [],
      ),
    );

    expect(find.text(TodayCopy.firstChildTitle), findsOneWidget);
    expect(find.text(TodayCopy.addChild), findsOneWidget);
  });

  testWidgets('a grant that opens none of them is pointed at More', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      TodayScreen(onSelectTab: (_) {}),
      view: Fixtures.helperView(
        AccessGrant({HouseholdArea.homeCare: AccessLevel.own}),
      ),
      providers: const [],
    );
    await tester.pumpAndSettle();

    expect(find.text(TodayCopy.nothingHere), findsOneWidget);
    expect(find.text(TodayCopy.lunchEyebrow.toUpperCase()), findsNothing);
  });

  testWidgets('it holds at phone width, in dark, at 200% text', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await pumpFamily(tester, brightness: Brightness.dark, textScale: 2);

    expect(tester.takeException(), isNull);
  });
}
