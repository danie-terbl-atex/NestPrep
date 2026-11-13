import 'dart:typed_data';

import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/best_effort.dart';
import '../data/own_recipe_photo_store.dart';
import '../data/own_recipe_repository.dart';
import '../model/own_recipe_ids.dart';
import '../model/own_recipe_photo_paths.dart';
import '../model/recipe_draft.dart';
import '../model/recipe_form.dart';

/// Saves a drafted recipe as it is, for an import of several where nobody
/// reviews each one (recipes ADR-0009). The same form, paths and call as the
/// builder, so what lands is what the builder would have saved.
final class OwnRecipeImporter {
  const OwnRecipeImporter({
    required this._ownRecipes,
    required this._photoStore,
    required this.householdId,
    required this.viewerUid,
  });

  final OwnRecipeRepository _ownRecipes;
  final OwnRecipePhotoStore _photoStore;
  final String householdId;
  final String viewerUid;

  /// A missing serving count takes the builder's default; null when the
  /// recipe has no ingredients or no method, which only a person can add.
  static RecipeForm? savableForm(RecipeDraft draft) {
    final read = RecipeForm.fromDraft(draft);
    final form = read.servings.isEmpty
        ? read.copyWith(servings: '${RecipeForm.defaultServings}')
        : read;
    return form.problems.isEmpty ? form : null;
  }

  /// False when it needs finishing in the builder.
  Future<bool> save(RecipeDraft draft) async {
    final form = savableForm(draft);
    if (form == null) return false;
    final recipeId = OwnRecipeIds.newRecipeId();
    final stored = <String>[];
    try {
      for (final photo in form.photos.whereType<NewRecipeFormPhoto>()) {
        await _upload(
          OwnRecipePhotoPaths.card(householdId, recipeId, photo.photoId),
          photo.cuts.card.bytes,
          stored,
        );
        await _upload(
          OwnRecipePhotoPaths.hero(householdId, recipeId, photo.photoId),
          photo.cuts.hero.bytes,
          stored,
        );
      }
      await _ownRecipes.save(
        householdId: householdId,
        recipeId: recipeId,
        recipe: form.toSave(),
      );
      return true;
    } on UnavailableFailure {
      rethrow;
    } on AppFailure {
      for (final path in stored) {
        await bestEffort(
          'remove orphaned recipe photo',
          code: 'orphan-photo',
          run: () => _photoStore.remove(path),
        );
      }
      rethrow;
    }
  }

  Future<void> _upload(
    String path,
    Uint8List bytes,
    List<String> stored,
  ) async {
    await _photoStore.upload(path: path, uploaderUid: viewerUid, bytes: bytes);
    stored.add(path);
  }
}
