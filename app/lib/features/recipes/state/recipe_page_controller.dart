import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/state/action_failure.dart';
import '../../../shared/time/calendar_date.dart';
import '../../meal_planning/data/meal_repository.dart';
import '../../meal_planning/model/meal.dart';
import '../../meal_planning/model/week_plan.dart';
import '../model/recipe.dart';
import '../model/recipe_meal_lines.dart';
import '../model/recipe_scale.dart';
import '../model/scaled_ingredients.dart';
import 'recipe_catalogue_controller.dart';

/// One recipe opened to cook or plan (recipes ADR-0003): which recipe the
/// catalogue's one listener says it is, how many people it is being cooked
/// for, what has been ticked off while cooking, and adding it to the week.
///
/// The recipe itself is never copied: [followCatalogue] reads it off the
/// catalogue controller each time that changes (`FE-07`). The people, the
/// ticks and the done steps are this page's own and end with it — nothing
/// about a scale is stored but what adding it to the week writes (§5).
final class RecipePageController extends ChangeNotifier
    with ActionFailureHolder {
  RecipePageController({
    required MealRepository mealRepository,
    required this.householdId,
    required this.memberId,
    required this.recipeId,
    required this.familySize,
  }) : _meals = mealRepository {
    _subscription = _meals
        .watchMeals(householdId)
        .listen(_followMeals, onError: _onMealsError);
  }

  final MealRepository _meals;
  final String householdId;
  final String memberId;
  final String recipeId;

  /// Who a family meal starts out cooked for (`familySizeOf`).
  final int familySize;

  AsyncState<Recipe?> _recipe = const AsyncLoading();
  RecipeScale? _scale;
  List<IngredientGroup> _groups = const [];
  final _ticked = <int>{};
  final _done = <int>{};
  bool _isAdding = false;
  bool _isPlanned = false;
  late final StreamSubscription<List<Meal>> _subscription;

  /// Loading, failed, or the recipe — null when the catalogue does not hold
  /// it (retired, or never there), which the page says in place.
  AsyncState<Recipe?> get recipe => _recipe;

  /// Null until the recipe is in.
  RecipeScale? get scale => _scale;

  /// The ingredients at [scale], in their parts — derived once per change of
  /// scale (`FE-12`).
  List<IngredientGroup> get groups => _groups;

  bool isTicked(int ingredient) => _ticked.contains(ingredient);
  bool isDone(int step) => _done.contains(step);

  /// The household has planned this recipe — its meal is in their library
  /// (§6) — so what it still needs may be shopped for (recipes ADR-0005).
  bool get isPlanned => _isPlanned;

  /// The ingredients not ticked off, at [scale], in the recipe's order:
  /// what *Add to grocer* looks for.
  List<ScaledIngredient> get unticked => [
    for (final group in _groups)
      for (final line in group.lines)
        if (!_ticked.contains(line.index)) line,
  ]..sort((a, b) => a.index.compareTo(b.index));

  /// True while the recipe is being put on the week — the way in cannot be
  /// pressed again until it lands (`FE-10`).
  bool get isAdding => _isAdding;

  void followCatalogue(RecipeCatalogueController catalogue) {
    final next = switch (catalogue.catalogue) {
      AsyncLoading() => const AsyncLoading<Recipe?>(),
      AsyncFailure(:final failure) => AsyncFailure<Recipe?>(failure),
      AsyncData() => AsyncData<Recipe?>(catalogue.recipe(recipeId)),
    };
    final arrived = switch (next) {
      AsyncData(:final value?) => value,
      _ => null,
    };
    // The catalogue also changes when its filter does; the same recipe at
    // the same scale is nothing new for this page.
    if (arrived != null && identical(arrived, _current)) return;
    _recipe = next;
    if (arrived == null) {
      _scale = null;
      _groups = const [];
    } else if (_scale?.servings != arrived.servings) {
      _scale = RecipeScale(
        people: startingPeople(arrived),
        servings: arrived.servings,
      );
    }
    _regroup();
    notifyListeners();
  }

  /// A family meal starts at the family's size; anything else — a lunch-box
  /// treat, a tray of rusks — at what the recipe makes.
  int startingPeople(Recipe recipe) =>
      recipe.firstMeal != null && familySize > 0 ? familySize : recipe.servings;

  void addPerson() => _setPeople((_scale?.people ?? 0) + 1);
  void removePerson() => _setPeople((_scale?.people ?? 0) - 1);

  /// Back to the recipe as written.
  void resetToRecipe() {
    final scale = _scale;
    if (scale != null) _setPeople(scale.servings);
  }

  void toggleIngredient(int index) => _toggle(_ticked, index);
  void toggleStep(int index) => _toggle(_done, index);

  /// Plans the recipe on [day]'s [slot] at the chosen scale (§6): the
  /// household meal it becomes, then the slot. False when it was refused,
  /// already under way, or there is nothing to add; the refusal is held for
  /// the page to say (`FE-09`).
  Future<bool> addToWeek({
    required CalendarDate day,
    required MealSlot slot,
  }) async {
    final recipe = _current;
    final scale = _scale;
    if (_isAdding || recipe == null || scale == null) return false;
    _isAdding = true;
    notifyListeners();
    var isAdded = false;
    try {
      await runAction(() async {
        final mealId = await _meals.addRecipeMeal(
          householdId: householdId,
          recipeId: recipe.id,
          name: recipe.name,
          ingredients: recipeMealLines(recipe, scale),
          addedBy: memberId,
        );
        await _meals.setSlot(
          householdId: householdId,
          monday: day.weekStart,
          slotKey: WeekPlan.slotKey(day.weekday, slot),
          mealId: mealId,
        );
        isAdded = true;
        _isPlanned = true;
      });
    } finally {
      _isAdding = false;
      notifyListeners();
    }
    return isAdded;
  }

  void _setPeople(int people) {
    final scale = _scale;
    if (scale == null) return;
    final next = scale.withPeople(people);
    if (next == scale) return;
    _scale = next;
    _regroup();
    notifyListeners();
  }

  Recipe? get _current => switch (_recipe) {
    AsyncData(:final value?) => value,
    _ => null,
  };

  void _regroup() {
    final scale = _scale;
    final recipe = _current;
    _groups = recipe == null || scale == null
        ? const []
        : scaledIngredientGroups(recipe.ingredients, scale);
  }

  void _followMeals(List<Meal> meals) {
    final id = Meal.idForRecipe(recipeId);
    final isPlanned = meals.any((meal) => meal.id == id);
    if (isPlanned == _isPlanned) return;
    _isPlanned = isPlanned;
    notifyListeners();
  }

  /// Not knowing whether it is planned hides the shopping card and says why
  /// in the page's banner; the recipe itself reads the catalogue, not the
  /// meals, and stays.
  void _onMealsError(Object error) =>
      recordFailure(error is AppFailure ? error : UnknownFailure(error));

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }

  void _toggle(Set<int> ticks, int index) {
    if (!ticks.remove(index)) ticks.add(index);
    notifyListeners();
  }
}
