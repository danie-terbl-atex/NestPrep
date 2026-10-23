import 'dart:async';

import 'package:nestprep/features/recipes/data/recipe_repository.dart';
import 'package:nestprep/features/recipes/model/recipe.dart';
import 'package:nestprep/features/recipes/model/recipe_link.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

/// Recipes answered by the test: [recipes] by id (catalogue and household
/// alike), or [failWith]; every request recorded, so a test can see which ids
/// were asked for. The catalogue is a stream the test drives with
/// [emitCatalogue] and [failCatalogueWith].
final class FakeRecipeRepository implements RecipeRepository {
  FakeRecipeRepository([Iterable<Recipe> recipes = const []])
    : recipes = {for (final recipe in recipes) recipe.id: recipe};

  final Map<String, Recipe> recipes;
  AppFailure? failWith;
  final asked = <Set<String>>[];
  final linked = <RecipeLink>[];

  /// While set, a linked read waits for it — the sheet's loading state.
  Completer<void>? hold;

  final _catalogue = StreamController<List<Recipe>>.broadcast();
  var catalogueListens = 0;

  void emitCatalogue(List<Recipe> recipes) => _catalogue.add(recipes);
  void failCatalogueWith(AppFailure failure) => _catalogue.addError(failure);
  Future<void> close() => _catalogue.close();

  @override
  Stream<List<Recipe>> watchCatalogue() {
    catalogueListens++;
    return _catalogue.stream;
  }

  @override
  Future<List<Recipe>> fetchByIds(Set<String> ids) async {
    asked.add(ids);
    final failure = failWith;
    if (failure != null) throw failure;
    return [for (final id in ids) ?recipes[id]];
  }

  @override
  Future<Recipe?> fetchLinked(String householdId, RecipeLink link) async {
    linked.add(link);
    await hold?.future;
    final failure = failWith;
    if (failure != null) throw failure;
    return recipes[link.recipeId];
  }
}
