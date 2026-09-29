import '../../features/groceries/model/grocery_amount.dart';
import '../../features/groceries/model/grocery_need_reason.dart';
import '../../features/groceries/model/grocery_plan_line.dart';
import '../../features/groceries/model/grocery_quantity.dart';
import '../../features/meal_planning/model/ingredient_unit.dart';
import 'app_copy.dart';

/// Every word the list says about the week's plans (groceries ADR-0002 to
/// ADR-0004), in a file of its own so parallel features do not edit the same
/// lines of `app_copy.dart` (`FE-19`).
abstract final class GroceryPlanCopy {
  // The way in, on the list.
  static const open = 'From this week’s plans';
  static String needs(int count) => count == 1
      ? 'This week’s plans need 1 thing'
      : 'This week’s plans need $count things';
  static const needsBody =
      'From your meals and lunch boxes. Nothing is added '
      'until you say so.';
  static const inStep = 'In step with this week’s plans';
  static const inStepBody =
      'What the meals and lunch boxes need is on the '
      'list, and comes off again if a plan changes.';
  static const review = 'Review';

  // The sheet.
  static const title = 'From this week’s plans';
  static String weekOf(String range) => 'Meals and lunch boxes · $range';
  static const keepInStep = 'Keep the list in step';
  static const keepInStepBody =
      'Adds and takes off what the plans need as '
      'they change. Never touches anything somebody typed or ticked.';
  static String turnedOnBy(String name) => 'Turned on by $name';
  static const keepInStepNeedsSight =
      'Keeping in step needs sight of every '
      'plan — ask a parent to share meals and lunch boxes with you.';

  static const toAdd = 'To add';
  static const toRefresh = 'Amounts changed';
  static const toRemove = 'No longer planned';
  static const recentlyBought = 'Bought recently';
  static const added = 'On the list from the plans';
  static const onList = 'Already on the list';
  static const staples = 'Usually in the house';
  static const staplesBody = 'Never proposed while they are marked.';

  static String now(String quantity) => 'Now $quantity';
  static const nowNoAmount = 'Reasons changed';
  static const removeBecause = 'No plan asks for this now';
  static String boughtAgo(Duration age) => switch (age.inDays) {
    < 1 => 'Bought today — add again?',
    1 => 'Bought yesterday — add again?',
    final days => 'Bought $days days ago — add again?',
  };
  static String markStapleFor(String name) => '$name is usually in the house';
  static String putBack(String name) => 'Put $name back on the plans';

  static String apply(int count) => count == 1
      ? 'Update the list · 1 change'
      : 'Update the list · $count changes';
  static const nothingChosen = 'Tick what should go on the list';
  static const selectAll = 'Tick all';
  static const selectNone = 'Untick all';

  static const emptyTitle = 'Nothing planned yet';
  static const emptyBody =
      'Plan this week’s meals or lunch boxes and what '
      'they need shows up here. A meal needs its ingredients first — add them '
      'from the meal library.';
  static const planMeals = 'Plan meals';
  static const planLunches = 'Plan lunches';
  static const allOnTheList = 'Everything the plans need is on the list.';

  // On the list itself.
  static const fromPlans = 'From the plans';
  static const editAdopts =
      'The plans put this here. Once you save a change '
      'it is yours, and the plans leave it alone.';

  // Why something is wanted.
  static const _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  /// *For 5 lunches + Tuesday dinner · Running low* — the sentence shown beside
  /// a proposal and stored on the item it becomes. [nameOf] turns a child's
  /// member id into their name, or null when it is not known.
  static String reasons(
    List<GroceryNeedReason> reasons, {
    required String? Function(String memberId) nameOf,
  }) {
    final meals = reasons.whereType<MealPlanReason>().toList();
    final plans = [
      for (final lunch in reasons.whereType<LunchPlanReason>())
        _lunches(lunch, nameOf),
      if (meals.isNotEmpty) _meals(meals),
    ];
    final sentence = [
      if (plans.isNotEmpty) 'For ${plans.join(' + ')}',
      for (final label in reasons.whereType<LabelledReason>()) label.label,
    ].join(' · ');
    return sentence.length <= GroceryPlanLine.noteLimit
        ? sentence
        : '${sentence.substring(0, GroceryPlanLine.noteLimit - 1)}…';
  }

  static String _lunches(
    LunchPlanReason lunch,
    String? Function(String memberId) nameOf,
  ) {
    final boxes = lunch.boxes == 1 ? '1 lunch' : '${lunch.boxes} lunches';
    final names = [for (final id in lunch.childIds) ?nameOf(id)];
    if (names.length == 1) {
      return lunch.boxes == 1
          ? '${names.single}’s lunch'
          : '${lunch.boxes} of ${names.single}’s lunches';
    }
    return names.isEmpty ? boxes : '$boxes (${names.join(', ')})';
  }

  static String _meals(List<MealPlanReason> meals) {
    String slot(MealPlanReason meal) =>
        '${_weekdays[meal.isoWeekday - 1]} '
        '${AppCopy.mealSlotName(meal.slot.name).toLowerCase()}';
    if (meals.length <= 2) return meals.map(slot).join(' + ');
    return '${slot(meals.first)} + ${meals.length - 1} more meals';
  }

  // How much.

  /// *2 loaves*, *1.5 kg + 1 pack*, *×3*; null when nothing says how much.
  static String? quantity(GroceryQuantity quantity) => quantity.isEmpty
      ? null
      : [for (final part in quantity.parts) amount(part)].join(' + ');

  static String amount(GroceryAmount amount) {
    final number = _number(amount.value);
    final isOne = amount.value == 1;
    return switch (amount.unit) {
      null => '×$number',
      IngredientUnit.pack => isOne ? '1 pack' : '$number packs',
      IngredientUnit.tin => isOne ? '1 tin' : '$number tins',
      IngredientUnit.loaf => isOne ? '1 loaf' : '$number loaves',
      IngredientUnit.bunch => isOne ? '1 bunch' : '$number bunches',
      IngredientUnit.bottle => isOne ? '1 bottle' : '$number bottles',
      final unit => '$number ${unit.code}',
    };
  }

  /// Whole numbers without a decimal; anything else to one place, which is
  /// all the rounding ever leaves (groceries ADR-0003).
  static String _number(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);
}
