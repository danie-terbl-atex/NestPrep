import '../../../shared/time/calendar_date.dart';
import '../../household/model/member.dart';
import '../../meal_planning/model/meal.dart';
import '../../meal_planning/model/week_plan.dart';
import '../../todos/model/occurrence_selector.dart';
import '../../todos/model/routine.dart';
import '../../todos/model/task.dart';
import '../../todos/model/task_completion.dart';
import '../../todos/model/task_occurrence.dart';

/// What a kid sees on their own device (accounts ADR-0003): who they are,
/// today's jobs, and today's food. Derived once per emission, never in a
/// build method (`FE-12`).
///
/// The jobs are the todos feature's own occurrences — the same expansion, the
/// same routine schedules, the same idea of done (`ENG-01`) — narrowed to the
/// ones that are this kid's and are today's, or were left undone recently.
class KidDay {
  const KidDay({
    required this.me,
    required this.today,
    required this.chores,
    required this.meals,
  });

  factory KidDay.from({
    required Member me,
    required CalendarDate today,
    required List<Task> tasks,
    required List<Routine> routines,
    required List<TaskCompletion> completions,
    required WeekPlan plan,
    required List<Meal> library,
  }) {
    final occurrences = selectOccurrences(
      tasks: tasks,
      routines: routines,
      completions: completions,
      from: windowStartFor(today),
      to: today,
    );
    final byId = {for (final meal in library) meal.id: meal};
    return KidDay(
      me: me,
      today: today,
      chores: [
        for (final occurrence in occurrences)
          if (occurrence.isFor(me.id) &&
              (occurrence.date == today || occurrence.isOverdue(today)))
            occurrence,
      ],
      meals: {
        for (final slot in MealSlot.values)
          slot: byId[plan.mealIdAt(today.weekday, slot) ?? ''],
      },
    );
  }

  /// How far back an unfinished job keeps asking — the todos feature's own
  /// horizon, so a kid and a parent agree about what is overdue.
  static CalendarDate windowStartFor(CalendarDate today) =>
      today.addDays(-overdueWindowDays);

  final Member me;
  final CalendarDate today;

  /// Overdue first, then today's, each in the todos feature's order.
  final List<TaskOccurrence> chores;

  /// What is planned for each meal today, or null for an empty slot.
  final Map<MealSlot, Meal?> meals;

  int get doneCount => chores.where((chore) => chore.isDone).length;

  bool get hasChores => chores.isNotEmpty;

  bool get isAllDone => hasChores && doneCount == chores.length;

  bool get hasFoodPlanned => meals.values.any((meal) => meal != null);
}
