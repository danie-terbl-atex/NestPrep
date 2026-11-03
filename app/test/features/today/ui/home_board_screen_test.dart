import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/app/household_shell.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/calendar/model/household_event.dart';
import 'package:nestprep/features/calendar/state/calendar_controller.dart';
import 'package:nestprep/features/groceries/model/grocery_item.dart';
import 'package:nestprep/features/groceries/state/grocery_list_controller.dart';
import 'package:nestprep/features/household/model/access_grant.dart';
import 'package:nestprep/features/household/model/access_level.dart';
import 'package:nestprep/features/household/model/household_area.dart';
import 'package:nestprep/features/today/model/home_layout.dart';
import 'package:nestprep/features/today/state/home_layout_controller.dart';
import 'package:nestprep/features/today/ui/home_board_screen.dart';
import 'package:nestprep/features/today/ui/today_screen.dart';
import 'package:nestprep/features/todos/model/task.dart';
import 'package:nestprep/features/todos/state/todo_controller.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/time/household_clock.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_calendar_repository.dart';
import '../../../support/fake_calendar_sync.dart';
import '../../../support/fake_grocery_repository.dart';
import '../../../support/fake_home_layout_store.dart';
import '../../../support/fake_todo_repository.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/lunch_fixtures.dart';
import '../../../support/lunch_harness.dart';
import '../../../support/pump_screen.dart';

void main() {
  late LunchHarness lunch;
  late FakeTodoRepository todoRepository;
  late FakeCalendarRepository calendarRepository;
  late FakeCalendarSyncRepository syncRepository;
  late FakeGroceryRepository groceryRepository;
  late TodoController todos;
  late CalendarController calendar;
  late GroceryListController groceries;
  late HomeLayoutController layout;

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
    layout = HomeLayoutController(
      store: FakeHomeLayoutStore(),
      canSwitch: true,
    );
  });

  tearDown(() async {
    todos.dispose();
    calendar.dispose();
    groceries.dispose();
    layout.dispose();
    await lunch.close();
  });

  Future<void> pumpFamily(
    WidgetTester tester,
    Widget screen, {
    Brightness brightness = Brightness.light,
    double textScale = 1,
  }) async {
    final today = LunchFixtures.week.dayOf(2);
    await pumpScreen(
      tester,
      screen,
      view: Fixtures.view(),
      brightness: brightness,
      textScale: textScale,
      providers: [
        ...lunch.providers,
        ChangeNotifierProvider<HomeLayoutController>.value(value: layout),
        ChangeNotifierProvider<TodoController>.value(value: todos),
        ChangeNotifierProvider<CalendarController>.value(value: calendar),
        ChangeNotifierProvider<GroceryListController>.value(value: groceries),
      ],
    );
    lunch.emit();
    todoRepository
      ..emitTasks([
        Task(
          id: 't1',
          title: 'Sign the trip form',
          dueDate: today,
          assigneeIds: const [Fixtures.samMemberId],
          createdBy: Fixtures.samMemberId,
        ),
      ])
      ..emitRoutines([])
      ..emitCompletions([]);
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
      ])
      ..emitExceptions([]);
    syncRepository
      ..emitConnections([])
      ..emitSynced([]);
    groceryRepository.emitItems([
      for (final (index, name) in ['Bread', 'Milk'].indexed)
        GroceryItem(
          id: 'g$index',
          name: name,
          addedBy: Fixtures.samMemberId,
          addedAt: LunchFixtures.nowUtc,
        ),
    ]);
    await tester.pumpAndSettle();
  }

  Finder card(String title) => find.descendant(
    of: find.byType(NestPlaceTile),
    matching: find.text(title),
  );

  testWidgets('family sees a card for every place, with what is on today', (
    tester,
  ) async {
    await pumpFamily(tester, HomeBoardScreen(onOpenTab: (_) {}));

    for (final title in [
      AppCopy.tabCalendar,
      AppCopy.tabTodos,
      AppCopy.tabGroceries,
      LunchCopy.tab,
      AppCopy.tabMeals,
    ]) {
      expect(card(title), findsOneWidget, reason: title);
    }
    expect(find.text(HomeBoardCopy.calendarToday(1)), findsOneWidget);
    expect(find.text(HomeBoardCopy.todoLeft(1)), findsOneWidget);
    expect(find.text(TodayCopy.groceryCount(2)), findsOneWidget);
    expect(find.byType(HouseholdTabBar), findsNothing);

    await tester.scrollUntilVisible(
      find.text(HomeBoardCopy.peopleTitle),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text(HomeBoardCopy.peopleTitle), findsOneWidget);
  });

  testWidgets('a card opens the tab it stands for', (tester) async {
    final opened = <HouseholdTab>[];
    await pumpFamily(tester, HomeBoardScreen(onOpenTab: opened.add));

    await tester.tap(card(AppCopy.tabGroceries));
    await tester.tap(card(AppCopy.tabCalendar));

    expect(opened, [HouseholdTab.groceries, HouseholdTab.week]);
  });

  testWidgets('a helper sees only the cards the grant opens', (tester) async {
    await pumpScreen(
      tester,
      HomeBoardScreen(onOpenTab: (_) {}),
      view: Fixtures.helperView(
        AccessGrant({HouseholdArea.homeCare: AccessLevel.own}),
      ),
      providers: [
        ChangeNotifierProvider<HomeLayoutController>.value(value: layout),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text(AppCopy.tabCalendar), findsNothing);
    expect(find.text(AppCopy.tabGroceries), findsNothing);
    expect(find.text(HomeCareCopy.openFromHousehold), findsOneWidget);
  });

  testWidgets('the header button switches Today to the cards and back', (
    tester,
  ) async {
    await pumpFamily(tester, TodayScreen(onSelectTab: (_) {}));

    await tester.tap(find.bySemanticsLabel(HomeBoardCopy.switchToCards));
    await tester.pump();
    expect(layout.layout, HomeLayout.cards);

    await tester.tap(find.bySemanticsLabel(HomeBoardCopy.switchToTabs));
    await tester.pump();
    expect(layout.layout, HomeLayout.tabs);
  });

  testWidgets('while the cards are on, a tab shows Home instead of the bar', (
    tester,
  ) async {
    final selected = <HouseholdTab>[];
    layout.switchLayout();
    await pumpFamily(tester, TodayScreen(onSelectTab: selected.add));

    expect(find.text(AppCopy.tabLists), findsNothing);
    await tester.tap(find.text(HomeBoardCopy.home));

    expect(selected, [HouseholdTab.today]);
  });

  testWidgets('it holds at phone width, in dark, at 200% text', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await pumpFamily(
      tester,
      HomeBoardScreen(onOpenTab: (_) {}),
      brightness: Brightness.dark,
      textScale: 2,
    );

    expect(tester.takeException(), isNull);
  });
}
