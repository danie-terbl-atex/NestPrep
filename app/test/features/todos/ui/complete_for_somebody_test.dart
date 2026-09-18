import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/todos/model/task.dart';
import 'package:nestprep/features/todos/model/task_completion.dart';
import 'package:nestprep/features/todos/state/todo_controller.dart';
import 'package:nestprep/features/todos/ui/todo_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/time/calendar_date.dart';
import 'package:nestprep/shared/time/household_clock.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../../support/fake_todo_repository.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';

/// A parent ticking off a child's task.
///
/// The controller has taken `forMemberId` since the beginning, the rules have
/// always allowed exactly this and refused everything near it, and two rules
/// tests prove the refusals. Nothing ever offered the choice, so none of it
/// could happen.
void main() {
  setUpAll(tz_data.initializeTimeZones);

  final today = CalendarDate.parse('2026-09-18');
  final now = DateTime.utc(2026, 9, 18, 6);

  late FakeTodoRepository repository;
  late TodoController controller;

  setUp(() {
    repository = FakeTodoRepository();
  });

  tearDown(() async {
    controller.dispose();
    await repository.close();
  });

  Future<void> pump(
    WidgetTester tester, {
    required String memberId,
    required bool isAdmin,
    required String viewerUid,
  }) {
    controller = TodoController(
      todoRepository: repository,
      householdClock: HouseholdClock('Africa/Johannesburg', now: () => now),
      householdId: Fixtures.householdId,
      memberId: memberId,
      isAdmin: isAdmin,
    );
    return pumpScreen(
      tester,
      TodoScreen(onSelectTab: (_) {}),
      view: Fixtures.view(viewerUid: viewerUid),
      providers: [
        ChangeNotifierProvider<TodoController>.value(value: controller),
      ],
    );
  }

  Task taskFor(List<String> assignees, {String id = 't1'}) => Task(
    id: id,
    title: 'Pack the swimming bag',
    dueDate: today,
    assigneeIds: assignees,
    createdBy: Fixtures.samMemberId,
  );

  Future<void> emit(
    WidgetTester tester, {
    required List<Task> tasks,
    List<TaskCompletion> completions = const [],
  }) async {
    repository.emitTasks(tasks);
    repository.emitRoutines([]);
    repository.emitCompletions(completions);
    await tester.pumpAndSettle();
    // Kid's task is on the household's list, not the admin's own.
    await tester.tap(find.text(AppCopy.todosEveryone));
    await tester.pumpAndSettle();
  }

  testWidgets('an admin is offered it for a profile nobody has claimed', (
    tester,
  ) async {
    await pump(
      tester,
      memberId: Fixtures.samMemberId,
      isAdmin: true,
      viewerUid: Fixtures.samUid,
    );
    await emit(
      tester,
      tasks: [
        taskFor([Fixtures.kidMemberId]),
      ],
    );

    expect(find.bySemanticsLabel(AppCopy.todosCompleteFor), findsOneWidget);
  });

  testWidgets('and not for somebody who has joined and can tick their own', (
    tester,
  ) async {
    await pump(
      tester,
      memberId: Fixtures.samMemberId,
      isAdmin: true,
      viewerUid: Fixtures.samUid,
    );
    await emit(
      tester,
      tasks: [
        taskFor([Fixtures.thandiMemberId]),
      ],
    );

    expect(find.bySemanticsLabel(AppCopy.todosCompleteFor), findsNothing);
  });

  testWidgets('and never to a helper, because the rules would refuse it', (
    tester,
  ) async {
    await pump(
      tester,
      memberId: Fixtures.thandiMemberId,
      isAdmin: false,
      viewerUid: Fixtures.thandiUid,
    );
    await emit(
      tester,
      tasks: [
        taskFor([Fixtures.kidMemberId]),
      ],
    );

    expect(find.bySemanticsLabel(AppCopy.todosCompleteFor), findsNothing);
  });

  testWidgets('one unclaimed assignee is not a choice, so it just happens', (
    tester,
  ) async {
    await pump(
      tester,
      memberId: Fixtures.samMemberId,
      isAdmin: true,
      viewerUid: Fixtures.samUid,
    );
    await emit(
      tester,
      tasks: [
        taskFor([Fixtures.kidMemberId]),
      ],
    );

    await tester.tap(find.bySemanticsLabel(AppCopy.todosCompleteFor));
    await tester.pumpAndSettle();

    final done = repository.completed.single;
    expect(done.taskId, 't1');
    expect(done.by, Fixtures.samMemberId, reason: 'the admin did it');
    expect(done.forMember, Fixtures.kidMemberId, reason: 'for the child');
  });

  testWidgets('the row says whose it was once it is done', (tester) async {
    await pump(
      tester,
      memberId: Fixtures.samMemberId,
      isAdmin: true,
      viewerUid: Fixtures.samUid,
    );
    await emit(
      tester,
      tasks: [
        taskFor([Fixtures.kidMemberId]),
      ],
      completions: [
        TaskCompletion(
          id: TaskCompletion.idFor('t1', today),
          taskId: 't1',
          occurrenceDate: today,
          completedBy: Fixtures.samMemberId,
          completedFor: Fixtures.kidMemberId,
        ),
      ],
    );

    expect(
      find.textContaining(AppCopy.todosDoneFor),
      findsOneWidget,
      reason: 'a task somebody else ticked off for you should say so',
    );
    expect(
      find.bySemanticsLabel(AppCopy.todosCompleteFor),
      findsNothing,
      reason: 'it is already done',
    );
  });
}
