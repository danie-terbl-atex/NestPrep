import '../model/own_recipe_save.dart';

abstract interface class OwnRecipeRepository {
  /// Safe to call again with the same [recipeId]: it writes the same recipe.
  Future<void> save({
    required String householdId,
    required String recipeId,
    required OwnRecipeSave recipe,
  });

  Future<void> delete({required String householdId, required String recipeId});
}
