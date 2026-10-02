import '../../../shared/failure/app_failure.dart';
import '../../add_to_checkers/data/checkers_catalogue.dart';
import '../../family_profiles/model/food_rules.dart';
import '../../live_location/model/coordinates.dart';
import '../data/lunch_aisle_source.dart';
import '../data/lunch_idea_drafter.dart';
import '../model/aisle_shelf.dart';
import '../model/checked_product.dart';
import '../model/idea_search.dart';
import '../model/lunch_idea.dart';

/// The start of step 2 (lunch-box ADR-0013): Checkers' own Kids Lunchbox
/// shelves, read one at a time near the household before the model drafts
/// anything, every product judged for the chosen children as a searched one
/// is. Each shelf becomes an idea already answered, its best kept products
/// first; a shelf that cannot be read is counted, said, and left out.
final class PlanWeekAisle {
  PlanWeekAisle({
    required this._source,
    required this._catalogue,
    required this.onChange,
  });

  /// What one shelf brings home to choose from: its best sellers.
  static const perShelf = 24;

  /// Product names per shelf the model hears of — the ones offered first.
  static const namesPerShelf = 6;

  final LunchAisleSource _source;
  final CheckersCatalogue _catalogue;
  final void Function() onChange;

  var _shelves = <IdeaSearch>[];
  var _isReading = false;
  var _read = 0;
  var _total = 0;
  var _unread = 0;
  var _generation = 0;

  /// Each shelf read, as an answered idea.
  List<IdeaSearch> get shelves => List.unmodifiable(_shelves);
  bool get isReading => _isReading;

  /// Shelves read so far, of [total].
  int get shelvesRead => _read;
  int get total => _total;

  /// Shelves that could not be read at all.
  int get unread => _unread;

  /// What the model hears of the shelves: the names of each one's best kept
  /// products, for the shelves with any.
  List<AisleShelfNames> get forModel => [
    for (final shelf in _shelves)
      if (shelf.kept.isNotEmpty)
        (
          slot: shelf.idea.slot,
          title: shelf.idea.idea,
          products: [
            for (final product in shelf.kept.take(namesPerShelf))
              product.product.name,
          ],
        ),
  ];

  Future<void> read({
    required Coordinates near,
    required Map<String, FoodRules> rulesByChild,
  }) async {
    final generation = ++_generation;
    _shelves = [];
    _read = 0;
    _total = 0;
    _unread = 0;
    _isReading = true;
    onChange();
    final shelves = await _source.shelves();
    if (generation != _generation) return;
    _total = shelves.length;
    onChange();
    for (final (index, shelf) in shelves.indexed) {
      final answered = await _readShelf(index, shelf, near, rulesByChild);
      if (generation != _generation) return;
      _read++;
      if (answered == null) {
        _unread++;
      } else {
        _shelves = [..._shelves, answered];
      }
      onChange();
    }
    _isReading = false;
    onChange();
  }

  /// Forgets the shelves; a read still on its way is dropped.
  void clear() {
    _generation++;
    _shelves = [];
    _isReading = false;
    _read = 0;
    _total = 0;
    _unread = 0;
  }

  /// The first of the shelf's sources with anything on it, judged — or null
  /// when none could be read.
  Future<IdeaSearch?> _readShelf(
    int index,
    AisleShelf shelf,
    Coordinates near,
    Map<String, FoodRules> rulesByChild,
  ) async {
    var anyRead = false;
    for (final source in shelf.sources) {
      try {
        final products = await _catalogue.shelf(
          shelf: source,
          near: near,
          limit: perShelf,
        );
        anyRead = true;
        if (products.isEmpty) continue;
        return _answered(index, shelf, [
          for (final product in products)
            CheckedProduct.of(product, rulesByChild),
        ]);
      } on AppFailure {
        continue;
      }
    }
    return anyRead ? _answered(index, shelf, const []) : null;
  }

  static IdeaSearch _answered(
    int index,
    AisleShelf shelf,
    List<CheckedProduct> found,
  ) {
    final childIds = <String>{for (final product in found) ...product.childIds};
    final idea = LunchIdea(
      id: 'aisle-${index + 1}',
      slot: shelf.slot,
      idea: shelf.title,
      searchTerm: shelf.title,
      why: '',
      childIds: childIds.toList()..sort(),
      excluded: const [],
      origin: IdeaOrigin.aisle,
    );
    return IdeaSearch.waiting(idea).answered(_bestFirst(found));
  }

  /// Kept for the most children first, then the shelf's own order — best
  /// sellers first; what was left out after.
  static List<CheckedProduct> _bestFirst(List<CheckedProduct> found) {
    final order = {for (final (i, product) in found.indexed) product: i};
    return [...found]..sort(
      (a, b) => switch (b.childIds.length.compareTo(a.childIds.length)) {
        0 => order[a]!.compareTo(order[b]!),
        final byChildren => byChildren,
      },
    );
  }
}
