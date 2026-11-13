import 'package:flutter/foundation.dart';

import '../../../shared/state/action_failure.dart';
import '../data/own_recipe_repository.dart';
import '../data/recipe_photo_source.dart';
import '../model/recipe.dart';

final class OwnRecipeDeleter extends ChangeNotifier with ActionFailureHolder {
  OwnRecipeDeleter({
    required this._ownRecipes,
    required this._photoSource,
    required this.householdId,
  });

  final OwnRecipeRepository _ownRecipes;
  final RecipePhotoSource _photoSource;
  final String householdId;

  bool _isDeleting = false;
  bool _isDisposed = false;

  bool get isDeleting => _isDeleting;

  @override
  void notifyListeners() {
    if (!_isDisposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<bool> delete(Recipe recipe) async {
    if (_isDeleting) return false;
    _isDeleting = true;
    notifyListeners();
    var isDeleted = false;
    await runAction(() async {
      await _ownRecipes.delete(householdId: householdId, recipeId: recipe.id);
      await _photoSource.forget([
        for (final photo in [?recipe.photo, ...recipe.gallery]) ...[
          photo.card,
          photo.hero,
        ],
      ]);
      isDeleted = true;
    });
    _isDeleting = false;
    notifyListeners();
    return isDeleted;
  }
}
