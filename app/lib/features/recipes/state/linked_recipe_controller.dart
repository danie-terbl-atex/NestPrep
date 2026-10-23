import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../data/recipe_repository.dart';
import '../model/recipe.dart';
import '../model/recipe_link.dart';

/// The one recipe a lunch item names, read when the sheet opens — never in a
/// build (`FE-05`). Null in [state] is the recipe not being there (missing,
/// retired, unreadable by this build), which the sheet says in place; a read
/// that fails is a failure with a retry (`FE-08`).
final class LinkedRecipeController extends ChangeNotifier {
  LinkedRecipeController({
    required this._recipes,
    required this.householdId,
    required this.link,
  }) {
    _load();
  }

  final RecipeRepository _recipes;
  final String householdId;
  final RecipeLink link;

  AsyncState<Recipe?> _state = const AsyncLoading();
  var _isDisposed = false;

  AsyncState<Recipe?> get state => _state;

  Future<void> retry() => _load();

  Future<void> _load() async {
    _set(const AsyncLoading());
    try {
      _set(AsyncData(await _recipes.fetchLinked(householdId, link)));
    } on AppFailure catch (failure) {
      _set(AsyncFailure(failure));
    }
  }

  void _set(AsyncState<Recipe?> state) {
    if (_isDisposed) return;
    _state = state;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
