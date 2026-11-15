import '../../../shared/copy/starter_copy.dart';
import '../../../shared/recurrence/recurrence_rule.dart';
import '../../../shared/time/calendar_date.dart';
import '../../calendar/model/household_event.dart';
import '../../groceries/model/grocery_item.dart';
import '../../meal_planning/model/ingredient_unit.dart';
import '../../meal_planning/model/meal.dart';
import '../../meal_planning/model/meal_ingredient.dart';
import '../../meal_planning/model/week_plan.dart';
import '../../todos/model/task.dart';

/// The examples a household is given the moment it is made, so its first
/// screens show what each place is for (household ADR-0010).
///
/// They are ordinary documents written as the person who made the household,
/// under ids that start with [idPrefix] — the only thing that marks one, so no
/// model or rule knows examples exist. Everything repeating ends within four
/// weeks: an example nobody cleared stops by itself.
final class StarterContent {
  StarterContent._({
    required this.tasks,
    required this.events,
    required this.groceries,
    required this.dinner,
    required this.dinnerWeek,
    required this.dinnerSlotKey,
  });

  factory StarterContent.forNewHousehold({
    required CalendarDate today,
    required String memberId,
  }) {
    final firstSchoolDay = _onOrAfter(today, const [1, 2, 3, 4, 5]);
    final wednesday = _onOrAfter(today.addDays(1), const [3]);
    final saturday = _onOrAfter(today.addDays(1), const [6]);
    final lastDay = today.addDays(_daysExamplesRepeat);

    return StarterContent._(
      tasks: [
        Task(
          id: '${idPrefix}task-complete',
          title: StarterCopy.taskComplete,
          dueDate: today,
          createdBy: memberId,
        ),
        Task(
          id: '${idPrefix}task-edit',
          title: StarterCopy.taskEdit,
          dueDate: today,
          createdBy: memberId,
        ),
        Task(
          id: '${idPrefix}task-slip',
          title: StarterCopy.taskSlip,
          note: StarterCopy.taskSlipNote,
          dueDate: today.addDays(2),
          assigneeIds: [memberId],
          createdBy: memberId,
        ),
        Task(
          id: '${idPrefix}task-bins',
          title: StarterCopy.taskBins,
          note: StarterCopy.taskBinsNote,
          dueDate: today.addDays(1),
          recurrence: RecurrenceRule(
            frequency: RecurrenceFrequency.weekly,
            until: lastDay,
          ),
          createdBy: memberId,
        ),
      ],
      events: [
        HouseholdEvent(
          id: '${idPrefix}event-welcome',
          title: StarterCopy.eventWelcome,
          note: StarterCopy.eventWelcomeNote,
          date: today,
          createdBy: memberId,
        ),
        HouseholdEvent(
          id: '${idPrefix}event-school-run',
          title: StarterCopy.eventSchoolRun,
          note: StarterCopy.eventSchoolRunNote,
          date: firstSchoolDay,
          startMinute: 7 * 60 + 15,
          endMinute: 7 * 60 + 45,
          recurrence: RecurrenceRule(
            frequency: RecurrenceFrequency.weekly,
            weekdays: const [1, 2, 3, 4, 5],
            until: lastDay,
          ),
          memberIds: [memberId],
          createdBy: memberId,
        ),
        HouseholdEvent(
          id: '${idPrefix}event-swimming',
          title: StarterCopy.eventSwimming,
          note: StarterCopy.eventSwimmingNote,
          date: wednesday,
          startMinute: 15 * 60,
          endMinute: 16 * 60,
          recurrence: RecurrenceRule(
            frequency: RecurrenceFrequency.weekly,
            until: lastDay,
          ),
          memberIds: [memberId],
          createdBy: memberId,
        ),
        HouseholdEvent(
          id: '${idPrefix}event-braai',
          title: StarterCopy.eventBraai,
          note: StarterCopy.eventBraaiNote,
          date: saturday,
          startMinute: 12 * 60 + 30,
          endMinute: 15 * 60,
          createdBy: memberId,
        ),
      ],
      groceries: [
        for (final (slug, name, quantity) in const [
          ('tick', StarterCopy.groceryTick, null),
          ('edit', StarterCopy.groceryEdit, null),
          ('milk', StarterCopy.groceryMilk, StarterCopy.groceryMilkQuantity),
          ('bread', StarterCopy.groceryBread, null),
          (
            'bananas',
            StarterCopy.groceryBananas,
            StarterCopy.groceryBananasQuantity,
          ),
          ('rooibos', StarterCopy.groceryRooibos, null),
        ])
          GroceryItem(
            id: '${idPrefix}grocery-$slug',
            name: name,
            quantity: quantity,
            addedBy: memberId,
          ),
      ],
      dinner:
          Meal.named(
            id: dinnerId,
            name: StarterCopy.mealDinner,
            addedBy: memberId,
          ).copyWith(
            ingredients: [
              MealIngredient.typed(
                name: StarterCopy.mealMince,
                amount: 500,
                unit: IngredientUnit.gram,
              ),
              MealIngredient.typed(
                name: StarterCopy.mealSpaghetti,
                amount: 500,
                unit: IngredientUnit.gram,
              ),
              MealIngredient.typed(
                name: StarterCopy.mealTomatoes,
                amount: 2,
                unit: IngredientUnit.tin,
              ),
              MealIngredient.typed(name: StarterCopy.mealOnion, amount: 1),
            ],
          ),
      dinnerWeek: today.weekStart,
      dinnerSlotKey: WeekPlan.slotKey(today.weekday, MealSlot.dinner),
    );
  }

  static const idPrefix = 'starter-';
  static const dinnerId = '${idPrefix}meal-dinner';
  static const _daysExamplesRepeat = 27;

  /// Ids are fixed, so clearing needs no query: these are all there ever were.
  static final StarterContent _shape = StarterContent.forNewHousehold(
    today: CalendarDate(2026, 1, 1),
    memberId: '',
  );

  static List<String> get taskIds => [for (final t in _shape.tasks) t.id];
  static List<String> get eventIds => [for (final e in _shape.events) e.id];
  static List<String> get groceryIds => [
    for (final g in _shape.groceries) g.id,
  ];

  static bool isExample(String id) => id.startsWith(idPrefix);

  final List<Task> tasks;
  final List<HouseholdEvent> events;
  final List<GroceryItem> groceries;
  final Meal dinner;
  final CalendarDate dinnerWeek;
  final String dinnerSlotKey;

  static CalendarDate _onOrAfter(CalendarDate from, List<int> weekdays) {
    var day = from;
    while (!weekdays.contains(day.weekday)) {
      day = day.addDays(1);
    }
    return day;
  }
}
