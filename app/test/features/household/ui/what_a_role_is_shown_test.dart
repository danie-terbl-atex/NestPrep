import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/app/household_shell.dart';
import 'package:nestprep/features/calendar/state/calendar_controller.dart';
import 'package:nestprep/features/calendar/ui/calendar_screen.dart';
import 'package:nestprep/features/groceries/state/grocery_list_controller.dart';
import 'package:nestprep/features/groceries/ui/grocery_add_field.dart';
import 'package:nestprep/features/groceries/ui/grocery_list_screen.dart';
import 'package:nestprep/features/household/model/access_defaults.dart';
import 'package:nestprep/features/household/model/access_grant.dart';
import 'package:nestprep/features/household/model/access_level.dart';
import 'package:nestprep/features/household/model/household_area.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/features/todos/model/task.dart';
import 'package:nestprep/features/todos/state/todo_controller.dart';
import 'package:nestprep/features/todos/ui/todo_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/time/calendar_date.dart';
import 'package:nestprep/shared/time/household_clock.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../../support/fake_calendar_repository.dart';
import '../../../support/fake_calendar_sync.dart';
import '../../../support/fake_grocery_repository.dart';
import '../../../support/fake_todo_repository.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_kit.dart';
import '../../../support/pump_screen.dart';

/// The app hides what a role cannot use (household ADR-0003). The rules
/// suite proves the server refuses it; this proves a helper is never shown
/// the button that would be refused — the other half of `FE-04`.
void main() {
  setUpAll(tz_data.initializeTimeZones);
  final now = DateTime.utc(2026, 9, 29, 9);

  /// The household as Thandi sees it, holding [grant].
  HouseholdView thandiWith(AccessGrant grant) => Fixtures.helperView(grant);

  group('the tab bar', () {
    testWidgets('shows a helper only the areas they may use', (tester) async {
      await pumpKit(
        tester,
        Provider<HouseholdView>.value(
          value: thandiWith(
            AccessGrant({
              HouseholdArea.groceries: AccessLevel.edit,
              HouseholdArea.todos: AccessLevel.own,
            }),
          ),
          child: HouseholdTabBar(
            current: HouseholdTab.groceries,
            onSelect: (_) {},
          ),
        ),
      );
      final handle = tester.ensureSemantics();
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel(AppCopy.tabGroceries), findsOneWidget);
      expect(find.bySemanticsLabel(AppCopy.tabTodos), findsOneWidget);
      expect(find.bySemanticsLabel(AppCopy.tabWeek), findsNothing);
      expect(find.bySemanticsLabel(AppCopy.tabMeals), findsNothing);
      handle.dispose();
    });
  });

  group('groceries a helper may only read', () {
    late FakeGroceryRepository repository;
    late GroceryListController controller;

    setUp(() {
      repository = FakeGroceryRepository();
      controller = GroceryListController(
        groceryRepository: repository,
        householdId: Fixtures.householdId,
        memberId: Fixtures.thandiMemberId,
        now: () => now,
      );
    });

    tearDown(() async {
      controller.dispose();
      await repository.close();
    });

    Future<void> pump(WidgetTester tester, AccessLevel level) async {
      await pumpScreen(
        tester,
        GroceryListScreen(onSelectTab: (_) {}),
        providers: [
          ChangeNotifierProvider<GroceryListController>.value(
            value: controller,
          ),
        ],
        view: thandiWith(AccessGrant({HouseholdArea.groceries: level})),
      );
      repository.emitItems(const []);
      await tester.pumpAndSettle();
    }

    testWidgets('offer no field to add to', (tester) async {
      await pump(tester, AccessLevel.view);
      expect(find.byType(GroceryAddField), findsNothing);
    });

    testWidgets('while a helper who may change them has one', (tester) async {
      await pump(tester, AccessLevel.edit);
      expect(find.byType(GroceryAddField), findsOneWidget);
    });
  });

  group('a week a helper may only look at', () {
    testWidgets('offers no way to add an event', (tester) async {
      final repository = FakeCalendarRepository();
      final controller = CalendarController(
        calendarRepository: repository,
        calendarSyncRepository: FakeCalendarSyncRepository(),
        householdClock: HouseholdClock('Africa/Johannesburg', now: () => now),
        householdId: Fixtures.householdId,
        memberId: Fixtures.thandiMemberId,
        householdMembers: const [],
      );
      addTearDown(() async {
        controller.dispose();
        await repository.close();
      });

      await pumpScreen(
        tester,
        CalendarScreen(onSelectTab: (_) {}),
        providers: [
          ChangeNotifierProvider<CalendarController>.value(value: controller),
        ],
        view: thandiWith(AccessDefaults.helper),
      );
      repository.emitEvents(const []);
      repository.emitExceptions(const []);
      await tester.pumpAndSettle();

      expect(find.text(AppCopy.calendarAddEvent), findsNothing);
    });
  });

  group('a kid whose chores are their own', () {
    late FakeTodoRepository repository;
    late TodoController controller;

    setUp(() {
      repository = FakeTodoRepository();
      controller = TodoController(
        todoRepository: repository,
        householdClock: HouseholdClock('Africa/Johannesburg', now: () => now),
        householdId: Fixtures.householdId,
        memberId: Fixtures.thandiMemberId,
        isAdmin: false,
        isOwnOnly: true,
        canEdit: false,
      );
    });

    tearDown(() async {
      controller.dispose();
      await repository.close();
    });

    test('asks for exactly their own tasks and ticks, and the routines', () {
      expect(repository.tasksAssignedTo, Fixtures.thandiMemberId);
      expect(repository.completionsFor, Fixtures.thandiMemberId);
      expect(
        repository.routinesWatched,
        1,
        reason:
            'the rules let `own` read routines, so a chore of theirs follows '
            'its routine\'s schedule (accounts ADR-0004)',
      );
    });

    testWidgets('sees their chores, with no everyone view and no add', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        TodoScreen(onSelectTab: (_) {}),
        providers: [
          ChangeNotifierProvider<TodoController>.value(value: controller),
        ],
        view: thandiWith(AccessDefaults.kid),
      );
      repository.emitTasks([
        Task(
          id: 'homework',
          title: 'Homework',
          dueDate: CalendarDate.parse('2026-09-29'),
          assigneeIds: const [Fixtures.thandiMemberId],
          createdBy: Fixtures.samMemberId,
        ),
      ]);
      repository
        ..emitRoutines(const [])
        ..emitCompletions(const []);
      await tester.pumpAndSettle();

      expect(find.text('Homework'), findsOneWidget);
      expect(find.text(AppCopy.todosEveryone), findsNothing);
      expect(find.text(AppCopy.todosAddTask), findsNothing);
    });
  });

  test('family still asks for everything, as before', () {
    final repository = FakeTodoRepository();
    final controller = TodoController(
      todoRepository: repository,
      householdClock: HouseholdClock('Africa/Johannesburg', now: () => now),
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
      isAdmin: true,
    );
    addTearDown(controller.dispose);
    expect(repository.tasksAssignedTo, isNull);
    expect(repository.routinesWatched, 1);
  });
}
