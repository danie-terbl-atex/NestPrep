import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../recipes/data/recipe_repository.dart';
import '../../recipes/model/recipe.dart';
import '../data/lunch_starter_box_repository.dart';
import '../model/lunch_starter_box.dart';

/// The ready-made boxes on offer, and the recipes their compartments name.
typedef StarterBoxOffer = ({
  List<LunchStarterBox> boxes,
  Map<String, Recipe> recipes,
});

/// NestPrep's ready-made boxes as *Fill the week* reads them (lunch-box
/// ADR-0020): fetched once when the flow opens, again on a retry. A failure
/// is held as this list's own state, so the rest of the step still works.
final class ReadyMadeBoxOffer {
  ReadyMadeBoxOffer({
    required this._boxes,
    required this._recipes,
    required this.onChange,
  });

  final LunchStarterBoxRepository _boxes;
  final RecipeRepository _recipes;
  final void Function() onChange;

  AsyncState<StarterBoxOffer> _state = const AsyncLoading();
  var _generation = 0;

  AsyncState<StarterBoxOffer> get state => _state;

  Future<void> load() async {
    final generation = ++_generation;
    _state = const AsyncLoading();
    onChange();
    AsyncState<StarterBoxOffer> next;
    try {
      final boxes = await _boxes.fetchPublished();
      final ids = {for (final box in boxes) ...box.recipeIds};
      final recipes = ids.isEmpty
          ? const <Recipe>[]
          : await _recipes.fetchByIds(ids);
      next = AsyncData((
        boxes: boxes,
        recipes: {for (final recipe in recipes) recipe.id: recipe},
      ));
    } on AppFailure catch (failure) {
      next = AsyncFailure(failure);
    }
    if (generation != _generation) return;
    _state = next;
    onChange();
  }

  /// An answer still on its way is dropped.
  void close() => _generation++;
}
