import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/household/ui/member_picker.dart';
import 'package:nestprep/features/todos/model/task.dart';
import 'package:nestprep/features/todos/model/task_completion.dart';
import 'package:nestprep/features/todos/state/todo_controller.dart';
import 'package:nestprep/features/todos/ui/todo_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/kid_copy.dart';
import 'package:nestprep/shared/copy/points_copy.dart';
import 'package:nestprep/shared/time/calendar_date.dart';
import 'package:nestprep/shared/time/household_clock.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../../support/fake_todo_repository.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/outside_the_bar.dart';
import '../../../support/pump_screen.dart';

void main() {
  setUpAll(tz_data.initializeTimeZones);

  final nowUtc = DateTime.utc(2026, 9, 18, 9);
  final today = CalendarDate.parse('2026-09-18');

  late FakeTodoRepository repository;
  late TodoController controller;

  setUp(() {
    repository = FakeTodoRepository();
    controller = TodoController(
      todoRepository: repository,
      householdClock: HouseholdClock('Africa/Johannesburg', now: () => nowUtc),
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
      isAdmin: true,
      kidIds: const [Fixtures.kidMemberId],
    );
  });

  tearDown(() async {
    controller.dispose();
    await repository.close();
  });

  Task bins() => Task(
    id: 'bins',
    title: 'Bins',
    dueDate: today,
    createdBy: Fixtures.samMemberId,
  );

  Task bed() => Task(
    id: 'bed',
    title: 'Make your bed',
    dueDate: today,
    assigneeIds: const [Fixtures.kidMemberId],
    createdBy: Fixtures.samMemberId,
    points: 3,
  );

  TaskCompletion doneAt(String taskId, DateTime? at, {String? by}) =>
      TaskCompletion(
        id: TaskCompletion.idFor(taskId, today),
        taskId: taskId,
        occurrenceDate: today,
        completedBy: by ?? Fixtures.samMemberId,
        completedFor: by ?? Fixtures.samMemberId,
        completedAt: at,
      );

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpScreen(
      tester,
      TodoScreen(onSelectTab: (_) {}),
      providers: [
        ChangeNotifierProvider<TodoController>.value(value: controller),
      ],
    );
  }

  Future<void> emit(
    WidgetTester tester, {
    List<Task> tasks = const [],
    List<TaskCompletion> completions = const [],
  }) async {
    repository.emitTasks(tasks);
    repository.emitRoutines([]);
    repository.emitCompletions(completions);
    await tester.pumpAndSettle();
  }

  Future<void> openChores(WidgetTester tester) async {
    await tester.tap(find.text(AppCopy.todosChoresChip(1)));
    await tester.pumpAndSettle();
  }

  testWidgets('a chore is not in Everyone; it is in Chores, under its kid', (
    tester,
  ) async {
    await pump(tester);
    await emit(tester, tasks: [bins(), bed()]);

    await tester.tap(find.text(AppCopy.todosEveryone));
    await tester.pumpAndSettle();
    expect(find.text('Bins'), findsOneWidget);
    expect(find.text('Make your bed'), findsNothing);
    expect(
      find.text(Fixtures.kid.displayName),
      findsNothing,
      reason: 'the member filter leaves the children to the Chores lens',
    );

    await openChores(tester);
    expect(find.text(Fixtures.kid.displayName), findsOneWidget);
    expect(find.text('Make your bed'), findsOneWidget);
    expect(find.text(AppCopy.todosChoresProgress(0, 1)), findsOneWidget);
    expect(find.text('Bins'), findsNothing);
  });

  testWidgets('a task for a grown-up and a kid is in Everyone and in Chores', (
    tester,
  ) async {
    await pump(tester);
    await emit(
      tester,
      tasks: [
        bed().copyWith(
          id: 'shop',
          title: 'Shop for school shoes',
          assigneeIds: const [Fixtures.samMemberId, Fixtures.kidMemberId],
          points: 0,
        ),
      ],
    );

    await tester.tap(find.text(AppCopy.todosEveryone));
    await tester.pumpAndSettle();
    expect(find.text('Shop for school shoes'), findsOneWidget);

    await openChores(tester);
    expect(find.text('Shop for school shoes'), findsOneWidget);
  });

  testWidgets('the sheet says where a task with a kid in it will show', (
    tester,
  ) async {
    await pump(tester);
    await emit(tester);
    await tester.tap(find.text(AppCopy.todosAddTask));
    await tester.pumpAndSettle();

    Future<void> pick(String name) async {
      final chip = find.descendant(
        of: find.byType(MemberPicker),
        matching: find.text(name),
      );
      await tester.ensureVisible(chip);
      await tester.tap(chip);
      await tester.pumpAndSettle();
    }

    expect(find.text(AppCopy.todosShowsOnChores), findsNothing);
    expect(find.text(AppCopy.todosShowsOnTodoAndChores), findsNothing);

    await pick(Fixtures.kid.displayName);
    expect(find.text(AppCopy.todosShowsOnChores), findsOneWidget);

    await pick('Sam Parent');
    expect(find.text(AppCopy.todosShowsOnChores), findsNothing);
    expect(find.text(AppCopy.todosShowsOnTodoAndChores), findsOneWidget);
  });

  testWidgets('a kid with nothing today still has a section that says so', (
    tester,
  ) async {
    await pump(tester);
    await emit(
      tester,
      tasks: [
        bins(),
        bed().copyWith(dueDate: today.addDays(2)),
      ],
    );

    await tester.tap(find.text(AppCopy.todosChores));
    await tester.pumpAndSettle();

    expect(find.text(AppCopy.todosNoChores), findsOneWidget);
  });

  testWidgets('Complete fills the tick, then moves the task to Just done', (
    tester,
  ) async {
    await pump(tester);
    await emit(tester, tasks: [bins()]);

    await tester.tap(find.text('Bins'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppCopy.todosComplete));
    await tester.pump();
    expect(
      repository.completed,
      isEmpty,
      reason: 'the tick is seen before it is written',
    );

    await tester.pumpAndSettle();
    expect(repository.completed.single.taskId, 'bins');
    expect(find.text(AppCopy.todosDoneToast('Bins')), findsOneWidget);

    repository.emitCompletions([
      doneAt('bins', nowUtc.subtract(const Duration(minutes: 2))),
    ]);
    await tester.pumpAndSettle();

    expect(find.text(AppCopy.todosJustDone), findsOneWidget);
    expect(textOutsideTheBar(AppCopy.todosToday), findsNothing);
    expect(
      find.textContaining(AppCopy.todosDoneAgo(AppCopy.minutesAgo(2))),
      findsOneWidget,
    );
  });

  testWidgets('a completion still waiting for the server is just done', (
    tester,
  ) async {
    await pump(tester);
    await emit(tester, tasks: [bins()], completions: [doneAt('bins', null)]);

    expect(find.text(AppCopy.todosJustDone), findsOneWidget);
    expect(
      find.textContaining(AppCopy.todosDoneAgo(AppCopy.timeJustNow)),
      findsOneWidget,
    );
  });

  testWidgets('what was done yesterday morning is no longer just done', (
    tester,
  ) async {
    await pump(tester);
    await emit(
      tester,
      tasks: [bins()],
      completions: [doneAt('bins', nowUtc.subtract(const Duration(hours: 25)))],
    );

    expect(find.text(AppCopy.todosJustDone), findsNothing);
  });

  testWidgets('Undo on the toast puts it back', (tester) async {
    await pump(tester);
    await emit(tester, tasks: [bins()]);

    await tester.tap(find.text('Bins'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppCopy.todosComplete));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppCopy.todosUndo));
    await tester.pumpAndSettle();

    expect(repository.uncompleted.single.taskId, 'bins');
  });

  testWidgets('the toast goes by itself once the undo window passes', (
    tester,
  ) async {
    await pump(tester);
    await emit(tester, tasks: [bins()]);

    await tester.tap(find.text('Bins'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppCopy.todosComplete));
    await tester.pumpAndSettle();
    expect(find.text(AppCopy.todosDoneToast('Bins')), findsOneWidget);

    await tester.pump(NestMotion.undoWindow);
    await tester.pumpAndSettle();
    expect(find.text(AppCopy.todosDoneToast('Bins')), findsNothing);
  });

  testWidgets('a just-done row opens on Not done', (tester) async {
    await pump(tester);
    await emit(
      tester,
      tasks: [bins()],
      completions: [
        doneAt('bins', nowUtc.subtract(const Duration(minutes: 5))),
      ],
    );

    await tester.tap(find.text('Bins'));
    await tester.pumpAndSettle();
    expect(find.text(AppCopy.todosComplete), findsNothing);
    await tester.tap(find.text(AppCopy.todosNotDone));
    await tester.pumpAndSettle();

    expect(repository.uncompleted.single.taskId, 'bins');
  });

  testWidgets('in Chores, an admin completes for the kid, and it celebrates', (
    tester,
  ) async {
    await pump(tester);
    await emit(tester, tasks: [bed()]);
    await openChores(tester);

    await tester.tap(find.text('Make your bed'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppCopy.todosComplete));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 300));

    final done = repository.completed.single;
    expect(done.by, Fixtures.samMemberId, reason: 'the admin did it');
    expect(done.forMember, Fixtures.kidMemberId, reason: 'the stars are hers');
    expect(find.text(KidCopy.allDone('Kid')), findsOneWidget);
    expect(find.text(PointsCopy.plusStars(3)), findsOneWidget);
    expect(find.byKey(NestCelebration.confettiKey), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text(KidCopy.allDone('Kid')), findsNothing, reason: 'it ends');
  });

  testWidgets('a chore that is not the last says well done', (tester) async {
    await pump(tester);
    await emit(
      tester,
      tasks: [
        bed(),
        bed().copyWith(id: 'teeth', title: 'Brush teeth', points: 0),
      ],
    );
    await tester.tap(find.text(AppCopy.todosChoresChip(2)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Brush teeth'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppCopy.todosComplete));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(KidCopy.wellDone('Kid')), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('to-dos outside Chores never celebrate', (tester) async {
    await pump(tester);
    await emit(tester, tasks: [bins()]);

    await tester.tap(find.text('Bins'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppCopy.todosComplete));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(NestCelebration), findsNothing);
    await tester.pumpAndSettle();
  });

  testWidgets('under reduce-motion it is the card alone, at once', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await pump(tester);
    await emit(tester, tasks: [bed()]);
    await openChores(tester);

    await tester.tap(find.text('Make your bed'));
    await tester.pump();
    await tester.tap(find.text(AppCopy.todosComplete));
    await tester.pump();
    await tester.pump();

    expect(repository.completed.single.forMember, Fixtures.kidMemberId);
    expect(find.text(KidCopy.allDone('Kid')), findsOneWidget);
    expect(find.byKey(NestCelebration.confettiKey), findsNothing);
    await tester.pumpAndSettle();
  });

  testWidgets('somebody who may only look is offered nothing to press', (
    tester,
  ) async {
    controller.dispose();
    controller = TodoController(
      todoRepository: repository,
      householdClock: HouseholdClock('Africa/Johannesburg', now: () => nowUtc),
      householdId: Fixtures.householdId,
      memberId: Fixtures.thandiMemberId,
      isAdmin: false,
      canEdit: false,
      kidIds: const [Fixtures.kidMemberId],
    );
    await pump(tester);
    await emit(tester, tasks: [bed()]);
    await openChores(tester);

    await tester.tap(find.text('Make your bed'));
    await tester.pumpAndSettle();

    expect(find.text(AppCopy.todosComplete), findsNothing);
  });
}
