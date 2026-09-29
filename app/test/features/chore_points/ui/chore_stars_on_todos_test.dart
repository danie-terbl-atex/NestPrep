import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/household/model/access_defaults.dart';
import 'package:nestprep/features/household/ui/member_picker.dart';
import 'package:nestprep/features/todos/model/task.dart';
import 'package:nestprep/features/todos/state/todo_controller.dart';
import 'package:nestprep/features/todos/ui/todo_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/points_copy.dart';
import 'package:nestprep/shared/time/calendar_date.dart';
import 'package:nestprep/shared/time/household_clock.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../../support/fake_todo_repository.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';

/// Stars on the to-dos tab (todos ADR-0003): a parent sets what a chore is
/// worth and whether they check it first; a starred chore names who earns it;
/// a helper is never offered the choice; and the row says what it is worth.
void main() {
  setUpAll(tz_data.initializeTimeZones);

  final now = DateTime.utc(2026, 9, 29, 7);
  final today = CalendarDate(2026, 9, 29);

  late FakeTodoRepository repository;
  late TodoController controller;

  setUp(() {
    repository = FakeTodoRepository();
    controller = TodoController(
      todoRepository: repository,
      householdClock: HouseholdClock('Africa/Johannesburg', now: () => now),
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
      isAdmin: true,
    );
  });

  tearDown(() async {
    controller.dispose();
    await repository.close();
  });

  Future<void> pump(WidgetTester tester, {bool asHelper = false}) async {
    await pumpScreen(
      tester,
      TodoScreen(onSelectTab: (_) {}),
      view: asHelper ? Fixtures.helperView(AccessDefaults.legacyHelper) : null,
      providers: [
        ChangeNotifierProvider<TodoController>.value(value: controller),
      ],
    );
    repository
      ..emitTasks([
        Task(
          id: 'room',
          title: 'Tidy your room',
          dueDate: today,
          assigneeIds: const [Fixtures.samMemberId],
          createdBy: Fixtures.samMemberId,
          points: 10,
          needsApproval: true,
        ),
      ])
      ..emitRoutines(const [])
      ..emitCompletions(const []);
    await tester.pumpAndSettle();
  }

  Future<void> openNewTask(WidgetTester tester) async {
    await tester.tap(find.text(AppCopy.todosAddTask));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Feed the cat');
    await tester.pump();
  }

  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('the row says what a chore is worth and that it is checked', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text(PointsCopy.starsChecked(10)), findsOneWidget);
  });

  testWidgets('a parent reaches stars and rewards from the tab', (
    tester,
  ) async {
    await pump(tester);
    expect(find.bySemanticsLabel(PointsCopy.screenTitle), findsOneWidget);
  });

  testWidgets('a parent gives a chore stars and a check, for somebody', (
    tester,
  ) async {
    await pump(tester);
    await openNewTask(tester);

    await reveal(tester, find.text(PointsCopy.starsCount(5)));
    await tester.tap(find.text(PointsCopy.starsCount(5)));
    await tester.pumpAndSettle();
    // Nobody picked yet: the sheet says so, and will not save.
    expect(find.text(PointsCopy.choreNeedsSomebody), findsOneWidget);
    await reveal(tester, find.text(AppCopy.householdSave));
    await tester.tap(find.text(AppCopy.householdSave));
    await tester.pumpAndSettle();
    expect(repository.savedTasks, isEmpty);

    final kidChip = find.descendant(
      of: find.byType(MemberPicker),
      matching: find.text('Kid Parker'),
    );
    await reveal(tester, kidChip);
    await tester.tap(kidChip);
    await tester.pump();
    await reveal(tester, find.text(PointsCopy.choreNeedsApproval));
    await tester.tap(find.text(PointsCopy.choreNeedsApproval));
    await tester.pump();
    await reveal(tester, find.text(AppCopy.householdSave));
    await tester.tap(find.text(AppCopy.householdSave));
    await tester.pumpAndSettle();

    final saved = repository.savedTasks.single;
    expect(saved.points, 5);
    expect(saved.needsApproval, isTrue);
    expect(saved.assigneeIds, [Fixtures.kidMemberId]);
  });

  testWidgets('a chore worth nothing has nothing to check', (tester) async {
    await pump(tester);
    await openNewTask(tester);
    await reveal(tester, find.text(AppCopy.householdSave));
    await tester.tap(find.text(AppCopy.householdSave));
    await tester.pumpAndSettle();
    expect(repository.savedTasks.single.points, 0);
    expect(repository.savedTasks.single.needsApproval, isFalse);
  });

  testWidgets('a helper is never offered stars, and no way in to them', (
    tester,
  ) async {
    await pump(tester, asHelper: true);
    expect(find.bySemanticsLabel(PointsCopy.screenTitle), findsNothing);
    await openNewTask(tester);
    expect(find.text(PointsCopy.choreStarsLabel), findsNothing);
  });
}
