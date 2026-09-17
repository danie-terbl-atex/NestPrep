import '../../../shared/time/calendar_date.dart';
import 'meal.dart';
import 'week_plan.dart';

/// One day of the week's plan, with the meals already looked up.
class PlannedDay {
  const PlannedDay({required this.date, required this.meals});

  final CalendarDate date;

  /// The meal in each slot, or null for an empty one.
  final Map<MealSlot, Meal?> meals;

  bool get isEmpty => meals.values.every((meal) => meal == null);
}

/// The week screen's view: seven days, each with its three slots resolved from
/// the library, so the screen never looks a meal up in a build method
/// (`FE-12`).
class MealWeek {
  const MealWeek({
    required this.weekStart,
    required this.today,
    required this.days,
    required this.library,
  });

  factory MealWeek.from({
    required CalendarDate weekStart,
    required CalendarDate today,
    required WeekPlan plan,
    required List<Meal> meals,
  }) {
    final byId = {for (final meal in meals) meal.id: meal};
    return MealWeek(
      weekStart: weekStart,
      today: today,
      library: meals,
      days: [
        for (var offset = 0; offset < WeekPlan.daysInAWeek; offset++)
          _dayAt(weekStart, offset, plan, byId),
      ],
    );
  }

  final CalendarDate weekStart;
  final CalendarDate today;
  final List<PlannedDay> days;

  /// Everything the household has eaten before, for the picker.
  final List<Meal> library;

  bool get isEmpty => days.every((day) => day.isEmpty);

  static PlannedDay _dayAt(
    CalendarDate weekStart,
    int offset,
    WeekPlan plan,
    Map<String, Meal> byId,
  ) {
    final date = weekStart.addDays(offset);
    return PlannedDay(
      date: date,
      meals: {
        for (final slot in MealSlot.values)
          slot: byId[plan.mealIdAt(date.weekday, slot) ?? ''],
      },
    );
  }
}
