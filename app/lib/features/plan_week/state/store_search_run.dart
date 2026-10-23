import '../../../shared/failure/app_failure.dart';
import '../../add_to_checkers/data/retailer_catalogue.dart';
import '../../family_profiles/model/food_rules.dart';
import '../../live_location/model/coordinates.dart';
import '../model/checked_product.dart';
import '../model/dish_draft.dart';
import '../model/idea_search.dart';
import '../model/ingredient_find.dart';
import '../model/lunch_idea.dart';

/// Step 3 of *Plan my week* (lunch-box ADR-0012): each idea searched at the
/// shop **one at a time** — kind to Checkers, whose catalogue client already
/// remembers and backs off — every answer judged for the idea's children as
/// it lands, so the screen can count the run as it goes.
///
/// A dish (lunch-box ADR-0021) is one search per ingredient, still in turn.
///
/// A run that is replaced (the parent went back, or started over) stops
/// reporting: an answer for an old run is dropped.
final class StoreSearchRun {
  StoreSearchRun({required this.onChange});

  /// What one search asks the shop for: enough to choose from, few enough to
  /// read.
  static const searchLimit = 8;

  /// Called after every change to [searches].
  final void Function() onChange;

  /// The chosen shop's catalogue, for the run in hand.
  late RetailerCatalogue _catalogue;
  var _searches = <IdeaSearch>[];
  var _generation = 0;

  List<IdeaSearch> get searches => List.unmodifiable(_searches);

  bool get isSettled => _searches.every((search) => search.isSettled);

  bool get hasKept => _searches.any((search) => search.hasKept);

  /// Searches every idea in [ideas] near [near], judging each product for
  /// the idea's children by [rulesByChild]. [answered] — the lunchbox
  /// aisle's shelves (lunch-box ADR-0013) — lead the list as they are.
  Future<void> start({
    required RetailerCatalogue catalogue,
    required List<LunchIdea> ideas,
    required Coordinates near,
    required Map<String, FoodRules> rulesByChild,
    List<IdeaSearch> answered = const [],
  }) async {
    final generation = ++_generation;
    _catalogue = catalogue;
    _searches = [
      ...answered,
      for (final idea in ideas) IdeaSearch.waiting(idea),
    ];
    onChange();
    for (final idea in ideas) {
      if (generation != _generation) return;
      await _search(idea.id, near, rulesByChild, generation);
    }
  }

  /// Forgets the run; anything still on its way is dropped.
  void clear() {
    _generation++;
    _searches = [];
  }

  Future<void> _search(
    String ideaId,
    Coordinates near,
    Map<String, FoodRules> rulesByChild,
    int generation,
  ) async {
    final index = _searches.indexWhere((search) => search.ideaId == ideaId);
    if (index < 0) return;
    final search = _searches[index];
    _replace(search.searching(), generation);
    final rules = {
      for (final childId in search.idea.childIds)
        childId: ?rulesByChild[childId],
    };
    final dish = search.idea.dish;
    IdeaSearch answered;
    if (dish != null) {
      answered = await _searchDish(search, dish, near, rules);
    } else {
      try {
        answered = search.answered(
          await _find(search.idea.searchTerm, near, rules),
        );
      } on AppFailure catch (failure) {
        answered = search.failedWith(failure);
      }
    }
    _replace(answered, generation);
  }

  /// A dish's ingredients, one search each, in turn (lunch-box ADR-0021 §3).
  /// One that fails is left to the household; only a dish whose every
  /// search failed is a failed search.
  Future<IdeaSearch> _searchDish(
    IdeaSearch search,
    DishDraft dish,
    Coordinates near,
    Map<String, FoodRules> rules,
  ) async {
    final finds = <IngredientFind>[];
    for (final ingredient in dish.ingredients) {
      try {
        final found = await _find(ingredient.searchTerm, near, rules);
        finds.add(IngredientFind(ingredient: ingredient, found: found));
      } on AppFailure catch (failure) {
        finds.add(IngredientFind(ingredient: ingredient, failure: failure));
      }
    }
    final firstFailure = finds.first.failure;
    return firstFailure != null && finds.every((find) => find.failure != null)
        ? search.failedWith(firstFailure)
        : search.answeredDish(finds);
  }

  Future<List<CheckedProduct>> _find(
    String query,
    Coordinates near,
    Map<String, FoodRules> rules,
  ) async {
    final products = await _catalogue.search(
      query: query,
      near: near,
      limit: searchLimit,
    );
    return [for (final product in products) CheckedProduct.of(product, rules)];
  }

  void _replace(IdeaSearch search, int generation) {
    if (generation != _generation) return;
    _searches = [
      for (final existing in _searches)
        existing.ideaId == search.ideaId ? search : existing,
    ];
    onChange();
  }
}
