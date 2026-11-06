import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/household/ui/member_picker.dart';
import 'package:nestprep/features/todos/model/task.dart';
import 'package:nestprep/features/todos/state/todo_controller.dart';
import 'package:nestprep/features/todos/ui/todo_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/time/calendar_date.dart';
import 'package:nestprep/shared/time/household_clock.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../test/support/fake_todo_repository.dart';
import '../test/support/household_fixtures.dart';
import 'review_press.dart';

/// Not a test — where a task with a kid in it shows (todos ADR-0006): the
/// task sheet saying so, and a grown-up-and-kid task in Everyone, in light and
/// dark, into `design-review/chores-where/`. Regenerate with
///
///     flutter test tool/chores_where_design_review_test.dart --update-goldens
void main() {
  setUpAll(() async {
    tz_data.initializeTimeZones();
    await loadEveryFont();
  });

  final nowUtc = DateTime.utc(2026, 11, 5, 7);
  final today = CalendarDate(2026, 11, 5);

  ({FakeTodoRepository repository, TodoController controller}) todoParts() {
    final repository = FakeTodoRepository();
    addTearDown(repository.close);
    final controller = TodoController(
      todoRepository: repository,
      householdClock: HouseholdClock('Africa/Johannesburg', now: () => nowUtc),
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
      isAdmin: true,
      kidIds: const [Fixtures.kidMemberId],
    );
    addTearDown(controller.dispose);
    return (repository: repository, controller: controller);
  }

  Task task(String id, String title, List<String> assignees) => Task(
    id: id,
    title: title,
    dueDate: today,
    assigneeIds: assignees,
    createdBy: Fixtures.samMemberId,
  );

  Future<void> emit(FakeTodoRepository repository) async {
    repository
      ..emitRoutines(const [])
      ..emitTasks([
        task('bins', 'Bins out', const []),
        task('bed', 'Make your bed', const [Fixtures.kidMemberId]),
        task('shoes', 'Shop for school shoes', const [
          Fixtures.samMemberId,
          Fixtures.kidMemberId,
        ]),
      ])
      ..emitCompletions(const []);
  }

  for (final brightness in [Brightness.light, Brightness.dark]) {
    for (final (name, picks) in [
      ('kid-only', [Fixtures.kid.displayName]),
      ('grown-up-and-kid', [Fixtures.kid.displayName, 'Sam Parent']),
    ]) {
      testWidgets('task sheet $name — ${brightness.name}', (tester) async {
        final parts = todoParts();
        await captureScreen(
          tester,
          'chores-where/task-sheet-$name-${brightness.name}',
          screen: TodoScreen(onSelectTab: (_) {}),
          providers: [
            ChangeNotifierProvider<TodoController>.value(
              value: parts.controller,
            ),
          ],
          brightness: brightness,
          emit: () => emit(parts.repository),
          act: () async {
            await tester.tap(find.text(AppCopy.todosAddTask));
            await tester.pumpAndSettle();
            await tester.enterText(find.byType(TextField).first, 'Tidy up');
            FocusManager.instance.primaryFocus?.unfocus();
            await tester.pumpAndSettle();
            for (final pick in picks) {
              final chip = find.descendant(
                of: find.byType(MemberPicker),
                matching: find.text(pick),
              );
              await tester.ensureVisible(chip);
              await tester.pumpAndSettle();
              await tester.tap(chip);
              await tester.pumpAndSettle();
            }
          },
        );
      });
    }

    testWidgets('everyone lens — ${brightness.name}', (tester) async {
      final parts = todoParts();
      await captureScreen(
        tester,
        'chores-where/everyone-${brightness.name}',
        screen: TodoScreen(onSelectTab: (_) {}),
        providers: [
          ChangeNotifierProvider<TodoController>.value(value: parts.controller),
        ],
        brightness: brightness,
        emit: () async {
          await emit(parts.repository);
          await tester.pumpAndSettle();
          await tester.tap(find.text(AppCopy.todosEveryone));
        },
      );
    });
  }
}
