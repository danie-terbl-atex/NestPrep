import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/household/ui/member_picker.dart';
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

import '../support/fake_todo_repository.dart';
import '../support/household_fixtures.dart';
import '../support/pump_screen.dart';

/// The one thing todos phase 1 still owed: the routine flow driven through the
/// screens, not through the controller.
///
/// An admin sets up "Laundry Day Tasks" every Saturday with the helper as its
/// default assignee; the helper's **Mine today**, on a Saturday, shows the three
/// tasks in it and can tick one off. Every step here is a tap or a keystroke on
/// the real widgets — the sheet, the recurrence editor, the member picker — so it
/// fails if any of them stops handing on what it collected.
///
/// What it does not prove is that this looks right on a phone. It proves the flow
/// exists and is wired end to end.

/// ISO-8601, the same as `DateTime.weekday`. `Weekday` names only its bounds.
const _saturday6 = 6;

/// A Saturday, in the household's own zone.
final _saturday = CalendarDate.parse('2026-09-19');
final _saturdayMorning = DateTime.utc(2026, 9, 19, 5);

const _laundry = 'Laundry Day Tasks';
const _routineId = 'r-laundry';

Task _taskInTheRoutine(String id, String title) => Task(
  id: id,
  title: title,
  // A task in a routine follows the routine's schedule; its own due date is
  // only the fallback, which is why these three carry a weekday that is not
  // Saturday and still land on one.
  dueDate: CalendarDate.parse('2026-09-16'),
  createdBy: Fixtures.samMemberId,
  routineId: _routineId,
);

/// A sheet is taller than the viewport, and a tap on something below the fold
/// lands on whatever *is* at that point instead — silently. Everything tapped
/// inside a sheet is scrolled to first.
Future<void> _tapInSheet(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

/// The member's name is on the screen behind the sheet too — the everyone view's
/// own filter — so a pick has to say which picker it means.
Finder _memberChip(String name) =>
    find.descendant(of: find.byType(MemberPicker), matching: find.text(name));

/// `NestTextField` puts its label above the input rather than inside it, so a
/// field is reached through the label's own widget.
Finder _fieldLabelled(String label) => find.descendant(
  of: find.ancestor(of: find.text(label), matching: find.byType(NestTextField)),
  matching: find.byType(TextField),
);

void main() {
  setUpAll(tz_data.initializeTimeZones);

  late FakeTodoRepository repository;

  setUp(() {
    repository = FakeTodoRepository();
  });

  tearDown(() => repository.close());

  TodoController controllerFor({
    required String memberId,
    required bool isAdmin,
  }) {
    final controller = TodoController(
      todoRepository: repository,
      householdClock: HouseholdClock(
        'Africa/Johannesburg',
        now: () => _saturdayMorning,
      ),
      householdId: Fixtures.householdId,
      memberId: memberId,
      isAdmin: isAdmin,
    );
    addTearDown(controller.dispose);
    return controller;
  }

  Future<void> pump(
    WidgetTester tester,
    TodoController controller, {
    String viewerUid = Fixtures.samUid,
  }) => pumpScreen(
    tester,
    TodoScreen(onSelectTab: (_) {}),
    view: Fixtures.view(viewerUid: viewerUid),
    providers: [
      ChangeNotifierProvider<TodoController>.value(value: controller),
    ],
  );

  Future<void> emit(
    WidgetTester tester, {
    List<Task> tasks = const [],
    List<Routine> routines = const [],
  }) async {
    repository.emitTasks(tasks);
    repository.emitRoutines(routines);
    repository.emitCompletions([]);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'an admin can reach the routine list on a household with nothing in it',
    (tester) async {
      await pump(
        tester,
        controllerFor(memberId: Fixtures.samMemberId, isAdmin: true),
      );
      await emit(tester);

      await tester.tap(find.text(AppCopy.todosEveryone));
      await tester.pumpAndSettle();

      // The first routine is created on a household that has no tasks yet, so an
      // empty state that replaces the everyone view takes away the only way in.
      expect(
        find.bySemanticsLabel(AppCopy.todosAddRoutine),
        findsOneWidget,
        reason: 'the empty everyone view must still offer the routine list',
      );
    },
  );

  testWidgets(
    'an admin builds Laundry Day Tasks every Saturday, usually for the helper',
    (tester) async {
      await pump(
        tester,
        controllerFor(memberId: Fixtures.samMemberId, isAdmin: true),
      );
      await emit(tester);

      await tester.tap(find.text(AppCopy.todosEveryone));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel(AppCopy.todosAddRoutine));
      await tester.pumpAndSettle();

      await tester.enterText(
        _fieldLabelled(AppCopy.todosRoutineNameLabel),
        _laundry,
      );
      await tester.pumpAndSettle();

      await _tapInSheet(tester, find.text(AppCopy.repeatWeekly));
      await _tapInSheet(tester, find.text(AppCopy.weekdayName(_saturday6)));
      await _tapInSheet(tester, _memberChip(Fixtures.thandi.displayName));

      await _tapInSheet(tester, find.text(AppCopy.householdSave));

      expect(repository.savedRoutines, hasLength(1));
      final saved = repository.savedRoutines.single;
      expect(saved.routineId, isNull, reason: 'a new routine, not an edit');
      expect(saved.name, _laundry);
      expect(saved.recurrence?.frequency, RecurrenceFrequency.weekly);
      expect(saved.recurrence?.weekdays, contains(_saturday6));
      expect(saved.defaultAssigneeIds, [Fixtures.thandiMemberId]);
    },
  );

  testWidgets(
    'a task added to the routine inherits its schedule and its helper',
    (tester) async {
      final controller = controllerFor(
        memberId: Fixtures.samMemberId,
        isAdmin: true,
      );
      await pump(tester, controller);
      await emit(
        tester,
        routines: [
          Routine(
            id: _routineId,
            name: _laundry,
            firstDate: _saturday,
            recurrence: const RecurrenceRule(
              frequency: RecurrenceFrequency.weekly,
              weekdays: [_saturday6],
            ),
            defaultAssigneeIds: const [Fixtures.thandiMemberId],
            createdBy: Fixtures.samMemberId,
          ),
        ],
      );

      await tester.tap(find.text(AppCopy.todosAddTask));
      await tester.pumpAndSettle();
      await tester.enterText(
        _fieldLabelled(AppCopy.todosTitleLabel),
        'Sort the whites',
      );
      await tester.pumpAndSettle();
      await _tapInSheet(tester, find.text(_laundry));
      await _tapInSheet(tester, find.text(AppCopy.householdSave));

      expect(repository.savedTasks, hasLength(1));
      final saved = repository.savedTasks.single;
      expect(saved.title, 'Sort the whites');
      expect(
        saved.routineId,
        _routineId,
        reason: 'the routine is what gives it a schedule',
      );
      expect(
        saved.assigneeIds,
        isEmpty,
        reason: "a task that names nobody inherits the routine's helper",
      );
    },
  );

  testWidgets(
    "on a Saturday the helper's Mine today shows the three, and one can be ticked",
    (tester) async {
      final controller = controllerFor(
        memberId: Fixtures.thandiMemberId,
        isAdmin: false,
      );
      await pump(tester, controller, viewerUid: Fixtures.thandiUid);
      await emit(
        tester,
        routines: [
          Routine(
            id: _routineId,
            name: _laundry,
            firstDate: _saturday,
            recurrence: const RecurrenceRule(
              frequency: RecurrenceFrequency.weekly,
              weekdays: [_saturday6],
            ),
            defaultAssigneeIds: const [Fixtures.thandiMemberId],
            createdBy: Fixtures.samMemberId,
          ),
        ],
        tasks: [
          _taskInTheRoutine('t1', 'Sort the whites'),
          _taskInTheRoutine('t2', 'Strip the beds'),
          _taskInTheRoutine('t3', 'Fold and put away'),
        ],
      );

      expect(find.text(AppCopy.todosToday), findsOneWidget);
      for (final title in [
        'Fold and put away',
        'Sort the whites',
        'Strip the beds',
      ]) {
        expect(
          find.text(title),
          findsOneWidget,
          reason: '$title is the helper\'s',
        );
      }

      // The whole row is the tick target, so tapping its title is a real tick.
      await tester.tap(find.text('Strip the beds'));
      await tester.pumpAndSettle();

      expect(repository.completed, hasLength(1));
      final done = repository.completed.single;
      expect(done.taskId, 't2');
      expect(done.date, _saturday);
      expect(done.by, Fixtures.thandiMemberId);
      expect(
        done.forMember,
        Fixtures.thandiMemberId,
        reason:
            'a helper completes for themselves, never on anybody else behalf',
      );
    },
  );
}
