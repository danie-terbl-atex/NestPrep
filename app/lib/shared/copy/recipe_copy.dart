import '../../features/meal_planning/model/ingredient_unit.dart';
import '../../features/recipes/model/recipe_difficulty.dart';
import '../../features/recipes/model/recipe_facet.dart';
import '../../features/recipes/model/recipe_meal_filter.dart';
import '../../features/recipes/model/recipe_shelf.dart';

/// Every word a recipe says, NestPrep's or a household's own (`FE-19`) — in a
/// sheet, on the Meals tab's recipes and on a recipe's own page (recipes
/// ADR-0003).
abstract final class RecipeCopy {
  static String prepMinutes(int minutes) => '$minutes min prep';
  static String serves(int servings) => 'Serves $servings';
  static const makeAhead = 'Make ahead';
  static String contains(String allergens) => 'Contains $allergens';
  static const containsNone = 'None of the common allergens';
  static const ingredientsHeader = 'Ingredients';
  static const stepsHeader = 'Method';
  static const aheadHeader = 'Making it ahead';
  static String stepNumber(int number) => '$number.';

  /// Under a recipe *Plan my week* drafted (recipes ADR-0002): honest about
  /// where it came from, and about checking it.
  static const draftedNote =
      'Drafted for your family by Plan my week. Check the labels of what '
      'you buy against your family\'s allergies.';

  /// The way into a recipe from a lunch box or the library — the row's own
  /// tap swaps or edits, so this is a button of its own.
  static String howToMake(String dish) => 'How to make $dish';
  static const howToMakeShort = 'How to make it';

  /// The recipe an item names is not there any more, or this build cannot
  /// read it — said in place, with nothing to retry.
  static const missingTitle = 'Recipe not found';
  static const missingMessage =
      'This recipe isn\'t available any more. The lunch itself is still in '
      'the box.';

  /// The same, on a recipe's own page — opened from a link or a planned
  /// meal, where there is no box to fall back on.
  static const pageMissingMessage =
      'This recipe isn\'t available any more. Anything you planned with it '
      'is still on your week.';

  /// "2 slices bread (wholewheat)", "Salt" — the amount only when the
  /// recipe gives one.
  static String ingredient({
    required String name,
    num? quantity,
    String? unit,
    String? note,
  }) {
    final amount = [?_amount(quantity), ?unit].join(' ');
    final line = amount.isEmpty ? name : '$amount $name';
    return note == null ? line : '$line ($note)';
  }

  /// A diet tag as stored ("vegetarian", "dairyFree") in sentence case; one
  /// this build does not know is spelled out from its name.
  static String dietTag(String tag) => switch (tag) {
    'glutenFree' => 'Gluten-free',
    'dairyFree' => 'Dairy-free',
    'banting' => 'Banting',
    'keto' => 'Keto',
    _ => _sentenceCase(tag),
  };

  static String _sentenceCase(String tag) {
    final words = tag
        .replaceAllMapped(RegExp('[A-Z]'), (match) => ' ${match[0]}')
        .replaceAll(RegExp('[-_]'), ' ')
        .trim()
        .toLowerCase();
    return words.isEmpty ? tag : words[0].toUpperCase() + words.substring(1);
  }

  static String? _amount(num? quantity) => switch (quantity) {
    null => null,
    final value when value == value.roundToDouble() => '${value.toInt()}',
    final value => '$value',
  };

  // The Meals tab's recipes (recipes ADR-0003).

  static const searchLabel = 'Search recipes';
  static const searchHint = 'Bobotie, chicken, pap…';
  static const clearSearch = 'Clear the search';

  static String meal(RecipeMealFilter meal) => switch (meal) {
    RecipeMealFilter.all => 'All',
    RecipeMealFilter.breakfast => 'Breakfast',
    RecipeMealFilter.lunch => 'Lunch',
    RecipeMealFilter.dinner => 'Dinner',
    RecipeMealFilter.sides => 'Sides',
    RecipeMealFilter.desserts => 'Desserts',
    RecipeMealFilter.lunchBox => 'Lunch box',
  };

  static String facet(RecipeFacet facet) => switch (facet) {
    RecipeFacet.braai => 'Braai',
    RecipeFacet.quick => 'Quick',
    RecipeFacet.healthy => 'Healthy',
    RecipeFacet.budget => 'Budget',
    RecipeFacet.kidFriendly => 'Kid-friendly',
    RecipeFacet.vegetarian => 'Vegetarian',
    RecipeFacet.banting => 'Banting',
    RecipeFacet.keto => 'Keto',
    RecipeFacet.glutenFree => 'Gluten-free',
    RecipeFacet.dairyFree => 'Dairy-free',
    RecipeFacet.traditional => 'Traditional',
    RecipeFacet.baking => 'Baking',
    RecipeFacet.onePot => 'One pot',
    RecipeFacet.comfort => 'Comfort food',
    RecipeFacet.capeMalay => 'Cape Malay',
    RecipeFacet.potjie => 'Potjie',
    RecipeFacet.festive => 'Festive',
    RecipeFacet.streetFood => 'Street food',
    RecipeFacet.vegetableForward => 'Veg-forward',
  };

  static const tonightEyebrow = 'Tonight’s idea';
  static const tonightAction = 'Cook this';

  static String shelf(RecipeShelfKind kind) => switch (kind) {
    RecipeShelfKind.healthyWeeknights => 'Healthy weeknights',
    RecipeShelfKind.sundayClassics => 'Sunday classics',
    RecipeShelfKind.braaiDay => 'Braai day',
    RecipeShelfKind.quickWeeknights => 'Quick weeknights',
    RecipeShelfKind.somethingSweet => 'Something sweet',
  };

  static const allRecipes = 'All recipes';
  static String matchCount(int count) =>
      count == 1 ? '1 recipe' : '$count recipes';

  /// Something was asked and nothing has it — said beside the controls that
  /// can change the question (`FE-08`).
  static const noMatchesTitle = 'Nothing matches that';
  static const noMatchesMessage =
      'Try fewer words, or another meal or kind of dish.';
  static const showEverything = 'Show all recipes';

  static const emptyTitle = 'Recipes are on their way';
  static const emptyMessage =
      'NestPrep’s family recipes appear here as soon as they are '
      'published.';

  /// "25 min", "1 h 20 min".
  static String minutes(int minutes) {
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    if (hours == 0) return '$minutes min';
    return rest == 0 ? '$hours h' : '$hours h $rest min';
  }

  static String difficulty(RecipeDifficulty difficulty) => switch (difficulty) {
    RecipeDifficulty.easy => 'Easy',
    RecipeDifficulty.medium => 'Medium',
    RecipeDifficulty.involved => 'Involved',
  };

  /// What a recipe card is to a screen reader: the whole card in one line.
  static String cardLabel({
    required String name,
    required int minutes,
    required int servings,
  }) => '$name, ${RecipeCopy.minutes(minutes)}, serves $servings';

  static const prepLabel = 'Prep';
  static const cookLabel = 'Cook';
  static const totalLabel = 'Total';
  static const difficultyLabel = 'Effort';
  static const servesLabel = 'Serves';
  static const energyLabel = 'Per serving';
  static String kcal(int kcal) => '~$kcal kcal';
  static String kcalSpoken(int kcal) => 'about $kcal kilocalories, estimated';
  static const dietHeader = 'Suits';
  static const aboutHeader = 'About this dish';
  static const allergensHeader = 'Allergens';

  // The people scaler.

  static const cookingFor = 'Cooking for';
  static String people(int count) => count == 1 ? 'person' : 'people';

  /// What the scaler is to a screen reader, as one sentence.
  static String cookingForLabel(int count) =>
      'Cooking for $count ${people(count)}';
  static const addPerson = 'Cook for one more';
  static const removePerson = 'Cook for one fewer';

  /// How far the recipe is scaled: "×1 1/2", "×2/3".
  static String scaleChip(String factor) => '×$factor';
  static String scaleLabel(String factor) => 'Recipe amounts times $factor';
  static const asWritten = 'As written';
  static String resetTo(int servings) => 'Reset to recipe (serves $servings)';

  /// What a unit reads as after an amount: "2 cups", "1 tin", "250 g".
  static String unit(IngredientUnit unit, double amount) {
    final isOne = amount <= 1;
    return switch (unit) {
      IngredientUnit.pack => isOne ? 'pack' : 'packs',
      IngredientUnit.tin => isOne ? 'tin' : 'tins',
      IngredientUnit.loaf => isOne ? 'loaf' : 'loaves',
      IngredientUnit.bunch => isOne ? 'bunch' : 'bunches',
      IngredientUnit.bottle => isOne ? 'bottle' : 'bottles',
      IngredientUnit.cup => isOne ? 'cup' : 'cups',
      _ => unit.code,
    };
  }

  /// A measured line's name and its note: "Onions, chopped".
  static String noted(String name, String note) => '$name, $note';

  /// A line with no amount: "Salt — to taste".
  static String unmeasured(String name, String? note) =>
      note == null ? name : '$name — $note';

  /// The amount as it leads an ingredient's line, before the name.
  static String amountBeforeName(String amount) => '$amount ';

  /// An ingredient row to a screen reader, with whether it is ticked off.
  static String ingredientLabel(String amount, String line) =>
      amount.isEmpty ? line : '$amount $line';
  static String stepLabel(int number, String step) => 'Step $number. $step';

  // The photo's credit (recipes ADR-0003 §4).

  static String photoCredit(String credit, String? licence) =>
      licence == null ? 'Photo: $credit' : 'Photo: $credit, $licence';
  static const photoIllustrative = 'Illustrative photo';
  static String withSource(String credit, String source) => '$credit · $source';
  static String photoOf(String dish) => 'A photo of $dish';

  // Adding it to the week (recipes ADR-0003 §6).

  static const addToWeek = 'Add to this week';
  static const addSheetTitle = 'Add to the week';
  static const thisWeek = 'This week';
  static const nextWeek = 'Next week';
  static const dayLabel = 'Day';
  static const mealLabel = 'Meal';
  static String forPeople(int count) => 'For $count ${people(count)}';
  static String addTo(String day, String meal) =>
      'Add to $day’s ${meal.toLowerCase()}';
  static String added(String dish, String day, String meal) =>
      '$dish is on $day’s ${meal.toLowerCase()}';
}
