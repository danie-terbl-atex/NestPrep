import '../../lunch_box/model/lunch_auto_fill.dart';
import '../../lunch_box/model/lunch_board.dart';
import '../../lunch_box/model/lunch_fill_bias.dart';
import '../../lunch_box/model/lunch_item.dart';
import '../../lunch_box/model/lunch_pick.dart';
import '../../lunch_box/model/lunch_plan.dart';
import '../../lunch_box/model/lunch_suggestions.dart';
import '../../meal_planning/model/meal.dart';
import '../../meal_planning/model/week_plan.dart';
import 'dinner_rotation.dart';
import 'plan_week_options.dart';
import 'plan_week_reply.dart';
import 'planned_week.dart';

/// What the review shows, from what the phone knows now (lunch-box ADR-0011):
/// the model's reply checked once more against each child's rules as this
/// phone last heard them, and every gap it left filled by the app's own
/// auto-fill (lunch-box ADR-0003) and dinner rotation — or, with no reply,
/// the whole week made that way and said so.
///
/// It never touches a compartment or a dinner somebody already filled.
abstract final class PlannedWeekBuilder {
  static PlannedWeek fromReply({
    required LunchBoard board,
    required PlanWeekOptions options,
    required PlanWeekReply reply,
    required List<Meal> meals,
    required WeekPlan? mealPlan,
    LunchFillBias? bias,
  }) => _build(
    board: board,
    options: options,
    reply: reply,
    meals: meals,
    mealPlan: mealPlan,
    bias: bias,
    source: PlanSource.ai,
    withDinners: options.includeDinners && reply.dinnersIncluded,
  );

  /// A plan made without AI: auto-fill for lunches, the rotation for dinners.
  static PlannedWeek fallback({
    required LunchBoard board,
    required PlanWeekOptions options,
    required List<Meal> meals,
    required WeekPlan? mealPlan,
    required PlanFallbackReason reason,
    required bool mayPlanDinners,
    LunchFillBias? bias,
  }) => _build(
    board: board,
    options: options,
    reply: null,
    meals: meals,
    mealPlan: mealPlan,
    bias: bias,
    source: PlanSource.fallback,
    reason: reason,
    withDinners: options.includeDinners && mayPlanDinners,
  );

  static PlannedWeek _build({
    required LunchBoard board,
    required PlanWeekOptions options,
    required PlanWeekReply? reply,
    required List<Meal> meals,
    required WeekPlan? mealPlan,
    required LunchFillBias? bias,
    required PlanSource source,
    required bool withDinners,
    PlanFallbackReason? reason,
  }) {
    final mealsById = {for (final meal in meals) meal.id: meal};
    final existingDinners = <int, Meal>{
      for (var day = 1; day <= WeekPlan.daysInAWeek; day++)
        day: ?mealsById[mealPlan?.mealIdAt(day, MealSlot.dinner)],
    };
    return PlannedWeek(
      week: board.week,
      source: source,
      fallbackReason: reason,
      callsLeft: reply?.callsLeft,
      dropped: reply?.dropped ?? 0,
      children: [
        for (final childWeek in board.children)
          if (options.childIds.contains(childWeek.childId))
            PlannedChildWeek(
              child: childWeek.child,
              existing: childWeek.plan,
              added: _lunchesFor(childWeek, board, reply, bias),
            ),
      ],
      dinnersIncluded: withDinners,
      existingDinners: existingDinners,
      dinners: withDinners
          ? _dinners(board, reply, meals, mealsById, mealPlan)
          : const {},
    );
  }

  static Map<String, PlannedPick> _lunchesFor(
    LunchChildWeek childWeek,
    LunchBoard board,
    PlanWeekReply? reply,
    LunchFillBias? bias,
  ) {
    final added = <String, PlannedPick>{};
    for (final lunch in reply?.lunches ?? const <ReplyLunch>[]) {
      if (lunch.childId != childWeek.childId) continue;
      final item = board.libraryById[lunch.itemId];
      final key = LunchPlan.slotKey(lunch.day, lunch.slot);
      if (item == null || !_mayGo(item, lunch, childWeek)) continue;
      if (childWeek.plan.slots.containsKey(key) || added.containsKey(key)) {
        continue;
      }
      added[key] = PlannedPick(item, PickOrigin.suggested);
    }
    final topUp = LunchAutoFill.fill(
      plan: childWeek.plan.copyWith(
        slots: {
          ...childWeek.plan.slots,
          for (final entry in added.entries)
            entry.key: LunchPick.of(entry.value.item),
        },
      ),
      week: board.week,
      favourites: childWeek.favourites,
      library: board.library,
      rules: childWeek.child.foodRules,
      taste: childWeek.taste,
      bias: bias,
    );
    for (final entry in topUp.picks.entries) {
      final item = board.libraryById[entry.value.itemId];
      if (item != null) added[entry.key] = PlannedPick(item, PickOrigin.filled);
    }
    return added;
  }

  /// The server checked this; the phone checks again against the rules it
  /// holds now — safe, not disliked, still in the library, in its own slot,
  /// and a treat on Friday only (lunch-box ADR-0001, ADR-0003).
  static bool _mayGo(LunchItem item, ReplyLunch lunch, LunchChildWeek week) {
    if (item.archived || item.slot != lunch.slot) return false;
    if (!lunch.slot.isAutoFilledOn(lunch.day)) return false;
    final suggestion = LunchSuggestions.suggestionFor(
      item,
      rules: week.child.foodRules,
      taste: week.taste,
    );
    return !suggestion.isUnsafe && !suggestion.isDisliked;
  }

  static Map<int, PlannedDinner> _dinners(
    LunchBoard board,
    PlanWeekReply? reply,
    List<Meal> meals,
    Map<String, Meal> mealsById,
    WeekPlan? mealPlan,
  ) {
    bool isEmpty(int day) =>
        (mealPlan?.mealIdAt(day, MealSlot.dinner) ?? '').isEmpty;
    final planned = <int, PlannedDinner>{};
    final used = <String>{
      for (var day = 1; day <= WeekPlan.daysInAWeek; day++)
        ?mealPlan?.mealIdAt(day, MealSlot.dinner),
    };
    for (final dinner in reply?.dinners ?? const <ReplyDinner>[]) {
      if (!isEmpty(dinner.day) || planned.containsKey(dinner.day)) continue;
      final meal = mealsById[dinner.mealId];
      final idea = dinner.idea;
      if (meal != null && used.add(meal.id)) {
        planned[dinner.day] = LibraryDinner(meal, PickOrigin.suggested);
      } else if (meal == null && idea != null) {
        planned[dinner.day] = IdeaDinner(idea);
      }
    }
    final rotated = DinnerRotation.fill(
      monday: board.week.monday,
      library: meals,
      emptyDays: [
        for (var day = 1; day <= WeekPlan.daysInAWeek; day++)
          if (isEmpty(day) && !planned.containsKey(day)) day,
      ],
      alreadyPlanned: used,
    );
    for (final entry in rotated.entries) {
      planned[entry.key] = LibraryDinner(entry.value, PickOrigin.filled);
    }
    return planned;
  }
}
