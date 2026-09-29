import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/accounts/model/kid_identity.dart';
import 'package:nestprep/features/kid_accounts/state/kid_home_controller.dart';
import 'package:nestprep/features/meal_planning/model/meal.dart';
import 'package:nestprep/features/meal_planning/model/week_plan.dart';
import 'package:nestprep/features/todos/model/task.dart';
import 'package:nestprep/features/todos/model/task_completion.dart';
import 'package:nestprep/shared/time/calendar_date.dart';
import 'package:nestprep/shared/time/household_clock.dart';

import 'fake_household.dart';
import 'fake_meal_repository.dart';
import 'fake_todo_repository.dart';
import 'household_fixtures.dart';

/// A kid device's home, behind fakes (accounts ADR-0003): the kid is
/// `Fixtures.kid`, and today in the household is Tuesday 29 September 2026.
final class KidHomeFixture {
  KidHomeFixture() {
    controller = KidHomeController(
      householdRepository: households,
      todoRepository: todos,
      mealRepository: meals,
      identity: identity,
      clockFor: (zone) => HouseholdClock(zone, now: () => nowUtc),
    );
  }

  static final nowUtc = DateTime.utc(2026, 9, 29, 7);
  static final today = CalendarDate(2026, 9, 29);

  static const identity = KidIdentity(
    householdId: Fixtures.householdId,
    memberId: Fixtures.kidMemberId,
  );

  final households = FakeHouseholdRepository();
  final todos = FakeTodoRepository();
  final meals = FakeMealRepository();
  late final KidHomeController controller;

  static Task chore(
    String id,
    String title, {
    CalendarDate? due,
    List<String> assigneeIds = const [Fixtures.kidMemberId],
  }) => Task(
    id: id,
    title: title,
    dueDate: due ?? today,
    assigneeIds: assigneeIds,
    createdBy: Fixtures.samMemberId,
  );

  static TaskCompletion done(String taskId, {CalendarDate? on}) =>
      TaskCompletion(
        id: TaskCompletion.idFor(taskId, on ?? today),
        taskId: taskId,
        occurrenceDate: on ?? today,
        completedBy: Fixtures.kidMemberId,
        completedFor: Fixtures.kidMemberId,
      );

  static const pasta = Meal(
    id: 'pasta',
    name: 'Pasta bake',
    nameKey: 'pasta bake',
    addedBy: Fixtures.samMemberId,
  );

  /// Everything the home reads, arriving in the order a real device sees it:
  /// the household first, because its zone says what today is.
  Future<void> arrive({
    List<Task> tasks = const [],
    List<TaskCompletion> completions = const [],
    Map<String, String> slots = const {},
  }) async {
    households.emitMember(Fixtures.kid);
    households.emitHousehold(Fixtures.household());
    await pumpEventQueue();
    todos
      ..emitTasks(tasks)
      ..emitRoutines(const [])
      ..emitCompletions(completions);
    meals
      ..emitWeek(WeekPlan(id: today.weekStart.iso, slots: slots))
      ..emitMeals(const [pasta]);
    await pumpEventQueue();
  }

  Future<void> close() async {
    controller.dispose();
    await households.close();
    await todos.close();
    await meals.close();
  }
}
