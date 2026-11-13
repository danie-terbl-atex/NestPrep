import 'package:cloud_functions/cloud_functions.dart';

import '../model/own_recipe_save.dart';
import 'own_recipe_failure_mapper.dart';
import 'own_recipe_repository.dart';

final class CallableOwnRecipeRepository implements OwnRecipeRepository {
  const CallableOwnRecipeRepository(this._functions);

  final FirebaseFunctions _functions;

  static Map<String, Object?> wireOf({
    required String householdId,
    required String recipeId,
    required OwnRecipeSave recipe,
  }) => {
    'householdId': householdId,
    'recipeId': recipeId,
    'name': recipe.name,
    'summary': recipe.summary,
    'notes': recipe.notes,
    'contexts': [for (final context in recipe.placement.keys) context.name],
    'placement': {
      for (final MapEntry(key: context, value: course)
          in recipe.placement.entries)
        context.name: course.name,
    },
    'ingredients': [
      for (final line in recipe.ingredients)
        {
          'name': line.name,
          'quantity': line.quantity,
          'unit': line.unit,
          'note': line.note,
          'group': line.group,
        },
    ],
    'steps': recipe.steps,
    'servings': recipe.servings,
    'prepMinutes': recipe.prepMinutes,
    'cookMinutes': recipe.cookMinutes,
    'origin': recipe.origin.name,
    'sourceUrl': recipe.sourceUrl,
    'sourceName': recipe.sourceName,
    'alsoContains': [for (final allergen in recipe.alsoContains) allergen.name],
    'photo': switch (recipe.photo) {
      final photo? => _photoWire(photo),
      null => null,
    },
    'gallery': [for (final photo in recipe.gallery) _photoWire(photo)],
  };

  static Map<String, Object?> _photoWire(OwnRecipePhotoRef photo) => {
    'photoId': photo.photoId,
    'credit': photo.credit,
    'sourceUrl': photo.sourceUrl,
  };

  @override
  Future<void> save({
    required String householdId,
    required String recipeId,
    required OwnRecipeSave recipe,
  }) => _call(
    'saveHouseholdRecipe',
    wireOf(householdId: householdId, recipeId: recipeId, recipe: recipe),
  );

  @override
  Future<void> delete({
    required String householdId,
    required String recipeId,
  }) => _call('deleteHouseholdRecipe', {
    'householdId': householdId,
    'recipeId': recipeId,
  });

  Future<void> _call(String name, Map<String, Object?> input) async {
    try {
      await _functions.httpsCallable(name).call<Object?>(input);
    } on FirebaseFunctionsException catch (error) {
      throw failureFromOwnRecipeCallable(error);
    }
  }
}
