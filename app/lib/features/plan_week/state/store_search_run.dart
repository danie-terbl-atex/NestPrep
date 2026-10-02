import '../../../shared/failure/app_failure.dart';
import '../../add_to_checkers/data/checkers_catalogue.dart';
import '../../family_profiles/model/food_rules.dart';
import '../../live_location/model/coordinates.dart';
import '../model/checked_product.dart';
import '../model/idea_search.dart';
import '../model/lunch_idea.dart';

/// Step 3 of *Plan my week* (lunch-box ADR-0012): each idea searched at the
/// shop **one at a time** — kind to Checkers, whose catalogue client already
/// remembers and backs off — every answer judged for the idea's children as
/// it lands, so the screen shows each row go from *waiting* to *searching* to
/// what was kept and what was left out, live.
///
/// A run that is replaced (the parent went back, or started over) stops
/// reporting: an answer for an old run is dropped.
final class StoreSearchRun {
  StoreSearchRun({required this._catalogue, required this.onChange});

  /// What one search asks the shop for: enough to choose from, few enough to
  /// read.
  static const searchLimit = 8;

  final CheckersCatalogue _catalogue;

  /// Called after every change to [searches].
  final void Function() onChange;

  var _searches = <IdeaSearch>[];
  var _generation = 0;

  List<IdeaSearch> get searches => List.unmodifiable(_searches);

  bool get isSettled => _searches.every((search) => search.isSettled);

  bool get hasKept => _searches.any((search) => search.kept.isNotEmpty);

  /// Searches every idea in [ideas] near [near], judging each product for
  /// the idea's children by [rulesByChild]. [answered] — the lunchbox
  /// aisle's shelves (lunch-box ADR-0013) — lead the list as they are.
  Future<void> start({
    required List<LunchIdea> ideas,
    required Coordinates near,
    required Map<String, FoodRules> rulesByChild,
    List<IdeaSearch> answered = const [],
  }) async {
    final generation = ++_generation;
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

  /// Searches one idea again — after a failure, say.
  Future<void> retry(
    String ideaId, {
    required Coordinates near,
    required Map<String, FoodRules> rulesByChild,
  }) => _search(ideaId, near, rulesByChild, _generation);

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
    IdeaSearch answered;
    try {
      final products = await _catalogue.search(
        query: search.idea.searchTerm,
        near: near,
        limit: searchLimit,
      );
      answered = search.answered([
        for (final product in products) CheckedProduct.of(product, rules),
      ]);
    } on AppFailure catch (failure) {
      answered = search.failedWith(failure);
    }
    _replace(answered, generation);
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
