import 'package:freezed_annotation/freezed_annotation.dart';

import '../../family_profiles/model/allergen.dart';
import '../../lunch_box/model/lunch_slot.dart';
import 'recipe_context.dart';
import 'recipe_course.dart';
import 'recipe_cuisine.dart';
import 'recipe_difficulty.dart';
import 'recipe_ingredient.dart';
import 'recipe_photo.dart';
import 'recipe_tag.dart';

part 'recipe.freezed.dart';

/// A recipe NestPrep publishes, at `recipes/{recipeId}`, or one a household
/// saved from *Plan my week*, at `households/{id}/recipes/{recipeId}`
/// (recipes ADR-0002) — read-only to the app, written by the backend. One domain for every meal: [contexts] says
/// where it belongs and [placement] where in that meal it goes, so the lunch
/// box reads the compartment it fills and breakfast, lunch and dinner the
/// course (recipes ADR-0003).
///
/// [allergens] are the fixed allergen codes, the same a lunch item carries,
/// so a recipe is checked against a child's food rules exactly like anything
/// else that goes in their box (lunch-box ADR-0001). A recipe only ever
/// reaches the app published; a retired one is not read.
///
/// Every field ADR-0003 added has a default, because a recipe published
/// before it — and a household's own — has none of them (`BE-10`).
@freezed
abstract class Recipe with _$Recipe {
  const factory Recipe({
    required String id,
    required String name,
    required String summary,
    required Set<RecipeContext> contexts,

    /// Context → where in that meal it goes, as stored (a slot name for the
    /// lunch box, a course for a meal). Read through [lunchSlot] and
    /// [courseIn].
    required Map<RecipeContext, String> placement,
    required Set<Allergen> allergens,
    required List<String> dietTags,
    required List<RecipeIngredient> ingredients,
    required List<String> steps,
    required int servings,
    required int prepMinutes,

    /// Worth making ahead on Sunday, like a lunch item that is.
    required bool prepAhead,
    String? prepNote,

    /// Drafted by *Plan my week* for this household (recipes ADR-0002), not
    /// written by NestPrep — the sheet says so.
    @Default(false) bool isAiDrafted,

    /// Where the dish comes from and why families love it.
    String? about,
    RecipeCuisine? cuisine,
    @Default(<RecipeTag>{}) Set<RecipeTag> tags,

    /// Time on the stove or in the oven, beside [prepMinutes].
    @Default(0) int cookMinutes,
    RecipeDifficulty? difficulty,
    RecipePhoto? photo,

    /// Estimated energy in one serving as written (recipes ADR-0006); a
    /// household's own recipe has none.
    int? kcalPerServing,
  }) = _Recipe;

  const Recipe._();

  static const vegetarianTag = 'vegetarian';
  static const veganTag = 'vegan';

  /// The lunch-box compartment it fills, or null when it is not for the
  /// lunch box or names a compartment this build does not know.
  LunchSlot? get lunchSlot => switch (placement[RecipeContext.lunchBox]) {
    final slot? => LunchSlot.fromName(slot),
    null => null,
  };

  /// The course it is in [context], or null when it is not offered there or
  /// names a course this build does not know.
  RecipeCourse? courseIn(RecipeContext context) =>
      RecipeCourse.fromName(placement[context]);

  /// Whether any family meal it is offered for has it as [course].
  bool isCourse(RecipeCourse course) =>
      contexts.any((context) => context.isMeal && courseIn(context) == course);

  int get totalMinutes => prepMinutes + cookMinutes;

  /// Vegan is vegetarian too.
  bool get isVegetarian =>
      dietTags.contains(vegetarianTag) || dietTags.contains(veganTag);

  /// The family meal it is first meant for — what *Add to this week*
  /// preselects — or null for a recipe only the lunch box offers. Dinner
  /// first, because a dish offered for lunch and dinner is a dinner that
  /// also does for lunch.
  RecipeContext? get firstMeal => const [
    RecipeContext.dinner,
    RecipeContext.lunch,
    RecipeContext.breakfast,
  ].where(contexts.contains).firstOrNull;
}
