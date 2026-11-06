import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/chore_points/state/kid_points_controller.dart';
import 'package:nestprep/features/kid_accounts/state/kid_home_controller.dart';
import 'package:nestprep/features/kid_accounts/ui/kid_home_screen.dart';
import 'package:nestprep/features/todos/model/task.dart';
import 'package:nestprep/features/todos/model/task_completion.dart';
import 'package:nestprep/features/todos/state/todo_controller.dart';
import 'package:nestprep/features/todos/ui/todo_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/chore_picture_copy.dart';
import 'package:nestprep/shared/time/calendar_date.dart';
import 'package:nestprep/shared/time/household_clock.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../test/support/fake_todo_repository.dart';
import '../test/support/household_fixtures.dart';
import '../test/support/kid_home_fixture.dart';
import 'review_press.dart';

/// Not a test — chore pictures' half of the screenshot press (todos
/// ADR-0005): the task sheet suggesting from the title, the picker, the kid's
/// home with pictured chores, and the parent's Chores lens, in light and
/// dark, into `design-review/chore-pictures/`. Regenerate with
///
///     flutter test tool/chore_pictures_design_review_test.dart --update-goldens
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

  Task chore(String id, String title, {String? picture, int points = 0}) =>
      Task(
        id: id,
        title: title,
        dueDate: today,
        assigneeIds: const [Fixtures.kidMemberId],
        createdBy: Fixtures.samMemberId,
        points: points,
        picture: picture,
      );

  Future<void> emitChores(FakeTodoRepository repository) async {
    repository
      ..emitRoutines(const [])
      ..emitTasks([
        chore('teeth', 'Brush your teeth', picture: 'brush-teeth', points: 1),
        chore('bed', 'Make your bed', picture: 'make-bed', points: 2),
        chore('dog', 'Feed Rex', picture: 'feed-dog', points: 2),
        chore('plants', 'Water the plants', picture: 'water-plants'),
        chore('bag', 'Pack your school bag'),
      ])
      ..emitCompletions([
        TaskCompletion(
          id: TaskCompletion.idFor('teeth', today),
          taskId: 'teeth',
          occurrenceDate: today,
          completedBy: Fixtures.kidMemberId,
          completedFor: Fixtures.kidMemberId,
          completedAt: nowUtc,
        ),
      ]);
  }

  Future<void> openSheet(WidgetTester tester, String title) async {
    await tester.tap(find.text(AppCopy.todosAddTask));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, title);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
  }

  for (final brightness in [Brightness.light, Brightness.dark]) {
    testWidgets('task sheet suggesting — ${brightness.name}', (tester) async {
      final parts = todoParts();
      await captureScreen(
        tester,
        'chore-pictures/task-sheet-suggestions-${brightness.name}',
        screen: TodoScreen(onSelectTab: (_) {}),
        providers: [
          ChangeNotifierProvider<TodoController>.value(value: parts.controller),
        ],
        brightness: brightness,
        emit: () => emitChores(parts.repository),
        act: () => openSheet(tester, 'Feed the dog and water the plants'),
      );
    });

    testWidgets('task sheet with one chosen — ${brightness.name}', (
      tester,
    ) async {
      final parts = todoParts();
      await captureScreen(
        tester,
        'chore-pictures/task-sheet-chosen-${brightness.name}',
        screen: TodoScreen(onSelectTab: (_) {}),
        providers: [
          ChangeNotifierProvider<TodoController>.value(value: parts.controller),
        ],
        brightness: brightness,
        emit: () => emitChores(parts.repository),
        act: () async {
          await openSheet(tester, 'Brush your teeth');
          await tester.tap(
            find.byKey(const ValueKey('chore-picture-suggestion-brush-teeth')),
          );
        },
      );
    });

    testWidgets('picker — ${brightness.name}', (tester) async {
      final parts = todoParts();
      await captureScreen(
        tester,
        'chore-pictures/picker-${brightness.name}',
        screen: TodoScreen(onSelectTab: (_) {}),
        providers: [
          ChangeNotifierProvider<TodoController>.value(value: parts.controller),
        ],
        brightness: brightness,
        emit: () => emitChores(parts.repository),
        act: () async {
          await openSheet(tester, 'Brush your teeth');
          final more = find.text(ChorePictureCopy.morePictures);
          await tester.ensureVisible(more);
          await tester.pumpAndSettle();
          await tester.tap(more);
        },
      );
    });

    testWidgets('chores lens — ${brightness.name}', (tester) async {
      final parts = todoParts();
      await captureScreen(
        tester,
        'chore-pictures/chores-lens-${brightness.name}',
        screen: TodoScreen(onSelectTab: (_) {}),
        providers: [
          ChangeNotifierProvider<TodoController>.value(value: parts.controller),
        ],
        brightness: brightness,
        emit: () async {
          await emitChores(parts.repository);
          await tester.pumpAndSettle();
          await tester.tap(find.text(AppCopy.todosChoresChip(4)));
        },
      );
    });

    testWidgets('kid home with pictures — ${brightness.name}', (tester) async {
      final fixture = (await tester.runAsync(() async => KidHomeFixture()))!;
      addTearDown(fixture.close);
      await captureScreen(
        tester,
        'chore-pictures/kid-home-${brightness.name}',
        screen: const KidHomeScreen(),
        providers: [
          ChangeNotifierProvider<KidHomeController>.value(
            value: fixture.controller,
          ),
          ChangeNotifierProvider<KidPointsController>.value(
            value: fixture.stars,
          ),
        ],
        brightness: brightness,
        emit: () => tester.runAsync(() async {
          await fixture.arrive(
            tasks: [
              KidHomeFixture.chore(
                'teeth',
                'Brush your teeth',
                picture: 'brush-teeth',
              ),
              KidHomeFixture.chore(
                'bed',
                'Make your bed',
                picture: 'make-bed',
                points: 2,
              ),
              KidHomeFixture.chore(
                'dog',
                'Feed Rex',
                picture: 'feed-dog',
                points: 3,
              ),
              KidHomeFixture.chore(
                'plants',
                'Water the plants',
                picture: 'water-plants',
              ),
              KidHomeFixture.chore('bag', 'Pack your school bag'),
            ],
            completions: [KidHomeFixture.done('teeth')],
          );
          await pumpEventQueue();
        }),
        act: () async {
          await tester.drag(screenList(), const Offset(0, -260));
        },
      );
    });
  }
}
