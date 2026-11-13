import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/server_timestamp_converter.dart';
import '../../../shared/text/normalised_name.dart';
import '../../recipes/model/recipe_link.dart';
import 'meal_ingredient.dart';
import 'meal_ingredients_converter.dart';

part 'meal.freezed.dart';
part 'meal.g.dart';

/// Something the household eats, at `households/{id}/meals/{mealId}`
/// (meal-planning ADR-0002, which keeps ADR-0001's library).
///
/// The library is not a list somebody maintains — it is what has been typed
/// before. Typing a name that is not in it creates the meal; picking from it
/// reuses one. So free text and the library are the same thing.
@freezed
abstract class Meal with _$Meal {
  const factory Meal({
    @JsonKey(includeToJson: false) required String id,
    required String name,

    /// [name] normalised, stored so the household can be asked "have we typed
    /// this before" in one query. It is derived, never typed — `Meal.named`
    /// is the only way to make one (`ENG-02`: the same normaliser groceries
    /// ranks its chips with).
    required String nameKey,
    required String addedBy,
    @ServerTimestampConverter() DateTime? createdAt,

    /// What it needs, which is what the grocery list fills itself from
    /// (meal-planning ADR-0002). Empty on a meal nobody has described.
    @MealIngredientsConverter()
    @Default(<MealIngredient>[])
    List<MealIngredient> ingredients,

    /// The catalogue recipe this meal was planned from (recipes ADR-0003 §6),
    /// set once when it is made and never changed — the meal plan shows the
    /// recipe's photo and *How to make it* for it. Never written as null: the
    /// rules allow the field only on a meal made from a recipe.
    @JsonKey(includeIfNull: false) String? recipeId,
    @JsonKey(includeIfNull: false) String? householdRecipeId,
  }) = _Meal;

  const Meal._();

  RecipeLink? get recipeLink =>
      RecipeLink.of(recipeId: recipeId, householdRecipeId: householdRecipeId);

  /// The only way to build a meal from something a person typed, so the stored
  /// key and the stored name can never disagree.
  factory Meal.named({
    required String id,
    required String name,
    required String addedBy,
  }) => Meal(
    id: id,
    name: name.trim(),
    nameKey: normalisedName(name),
    addedBy: addedBy,
  );

  /// A recipe's meal carries its link in the one field the rules allow for
  /// that kind of recipe (recipes ADR-0007 §6).
  factory Meal.ofRecipe({
    required RecipeLink link,
    required String name,
    required List<MealIngredient> ingredients,
    required String addedBy,
  }) => Meal.named(id: idForRecipe(link.recipeId), name: name, addedBy: addedBy)
      .copyWith(
        ingredients: ingredients,
        recipeId: link is CatalogueRecipeLink ? link.recipeId : null,
        householdRecipeId: link is HouseholdRecipeLink ? link.recipeId : null,
      );

  /// The meal a recipe becomes in this household's library: one per recipe,
  /// by id, so planning it again finds the same meal (recipes ADR-0003 §6).
  static String idForRecipe(String recipeId) => 'recipe-$recipeId';

  factory Meal.fromJson(Map<String, Object?> json) => _$MealFromJson(json);
}
