import '../../../shared/failure/app_failure.dart';
import '../../../shared/text/normalised_name.dart';
import '../../groceries/model/product_match.dart';
import '../data/checkers_place_resolver.dart';
import '../data/product_match_ranker.dart';
import '../data/retailer_catalogues.dart';
import '../model/checkers_area.dart';
import '../model/checkers_place.dart';
import '../model/retailer_product.dart';

/// Products in Jev's order, and the one Jev is sure of when it is sure.
typedef RankedProducts = ({
  List<RetailerProduct> products,
  String? bestMatchId,
});

/// Looks a grocery name up at a shop, near where the household is, and asks
/// Jev which product it means — for the grocery screen's panel under an item
/// and its matches as somebody types (add-to-checkers ADR-0003, ADR-0007).
/// One per screen, so both search from the same place, and a name already
/// looked up — or on its way — is not asked of the shop or Jev again: the
/// panel that opens under a newly added item shows what typing it found.
final class ProductFinder {
  ProductFinder({
    required this._catalogues,
    required CheckersPlaceResolver placeResolver,
    required this.householdId,
    this._ranker,
  }) : _places = placeResolver;

  /// Jev's score a match needs before it is called the best (foundation
  /// ADR-0021).
  static const bestMatchFit = 0.6;

  final RetailerCatalogues _catalogues;
  final CheckersPlaceResolver _places;
  final ProductMatchRanker? _ranker;
  final String householdId;

  CheckersPlace? _place;
  final _searches = <_Key, Future<List<RetailerProduct>>>{};
  final _ranks = <_Key, Future<RankedProducts?>>{};

  /// Where the last search looked, once it is known.
  CheckersPlace? get place => _place;

  /// Throws the shop's `AppFailure`.
  Future<List<RetailerProduct>> search(
    String query, {
    required ProductRetailer at,
  }) {
    final key = (at, normalisedName(query));
    if (_searches[key] case final known?) return known;
    final found = _searchAt(key, query);
    _searches[key] = found;
    return found;
  }

  Future<List<RetailerProduct>> _searchAt(_Key key, String query) async {
    try {
      final place = _place ??= await _places.resolve(householdId);
      return await _catalogues
          .of(key.$1)
          .search(query: query, near: place.coordinates);
    } on AppFailure {
      _searches.removeWhere((cached, _) => cached == key);
      rethrow;
    }
  }

  /// Searches this household's matches near [area] from now on.
  Future<void> chooseArea(CheckersArea area) async {
    await _places.choose(householdId, area);
    _place = CheckersPlace.area(area);
    _searches.clear();
    _ranks.clear();
  }

  /// [products] best first. Null when there is no ranker or it failed:
  /// ranking is a nicety, and the shop's order stands.
  Future<RankedProducts?> rank(String item, List<RetailerProduct> products) {
    final ranker = _ranker;
    if (ranker == null || products.isEmpty) return Future.value();
    final key = (products.first.retailer, normalisedName(item));
    if (_ranks[key] case final known?) return known;
    final ranked = _rankWith(ranker, key, item, products);
    _ranks[key] = ranked;
    return ranked;
  }

  Future<RankedProducts?> _rankWith(
    ProductMatchRanker ranker,
    _Key key,
    String item,
    List<RetailerProduct> products,
  ) async {
    try {
      return _ranked(
        products,
        await ranker.rank(
          householdId: householdId,
          item: item,
          products: products,
        ),
      );
    } on AppFailure {
      _ranks.removeWhere((cached, _) => cached == key);
      return null;
    }
  }

  static RankedProducts _ranked(
    List<RetailerProduct> products,
    Map<String, double> fits,
  ) {
    final ranked = [...products]
      ..sort((a, b) => (fits[b.id] ?? 0).compareTo(fits[a.id] ?? 0));
    final best = ranked.first;
    return (
      products: ranked,
      bestMatchId: (fits[best.id] ?? 0) >= bestMatchFit ? best.id : null,
    );
  }
}

typedef _Key = (ProductRetailer, String);
