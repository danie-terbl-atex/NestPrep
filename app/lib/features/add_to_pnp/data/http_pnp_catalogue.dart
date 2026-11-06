import 'package:http/http.dart' as http;

import '../../add_to_checkers/data/retailer_catalogue.dart';
import '../../add_to_checkers/model/retailer_product.dart';
import '../../add_to_checkers/model/retailer_shelf.dart';
import '../../live_location/model/coordinates.dart';
import 'pnp_catalogue_parser.dart';
import 'pnp_contents_reader.dart';
import 'pnp_occ_client.dart';
import 'pnp_store_finder.dart';

/// Pick n Pay's catalogue over HTTPS, unauthenticated (add-to-pnp ADR-0002):
/// the store PnP assigns to the point, then a search or a category at that
/// store, then each product's contents from its detail.
///
/// Kind to PnP on purpose, as the Checkers catalogue is to Checkers: the
/// store for a place, each detail and the last few searches are remembered
/// for the run, a search already in flight is shared, and a 429 stops every
/// call until its `Retry-After` has passed.
final class HttpPnpCatalogue implements RetailerCatalogue {
  HttpPnpCatalogue({http.Client? client, DateTime Function()? now})
    : this.over(PnpOccClient(client: client, now: now));

  HttpPnpCatalogue.over(PnpOccClient occ)
    : _occ = occ,
      _stores = PnpStoreFinder(occ),
      _contents = PnpContentsReader(occ);

  static const _recentSearchLimit = 40;

  /// The fields a list asks for — the website's own list, less what a
  /// lunch plan never reads.
  static const listFields =
      'products(code,name,price(FULL),images(DEFAULT),stock(FULL),'
      'quantityType,potentialPromotions(FULL),categoryNames)';

  final PnpOccClient _occ;
  final PnpStoreFinder _stores;
  final PnpContentsReader _contents;

  // Insertion-ordered, so the oldest search is the first to be forgotten.
  final _searches = <String, Future<List<RetailerProduct>>>{};

  @override
  Future<List<RetailerProduct>> search({
    required String query,
    required Coordinates near,
    int limit = RetailerCatalogue.defaultLimit,
  }) {
    final words = query.trim().replaceAll(':', ' ');
    return _products(query: '$words:relevance', near: near, limit: limit);
  }

  /// A category, in PnP's own relevance order — it offers no best sellers.
  @override
  Future<List<RetailerProduct>> shelf({
    required RetailerShelf shelf,
    required Coordinates near,
    int limit = RetailerCatalogue.defaultLimit,
  }) => switch (shelf.kind) {
    RetailerShelfKind.pnpCategory => _products(
      query: ':relevance:allCategories:${shelf.id}',
      near: near,
      limit: limit,
    ),
    // Another shop's shelf has no meaning here.
    RetailerShelfKind.productList ||
    RetailerShelfKind.displayCategory ||
    RetailerShelfKind.woolworthsGroup => throw ArgumentError.value(shelf.id),
  };

  Future<List<RetailerProduct>> _products({
    required String query,
    required Coordinates near,
    required int limit,
  }) async {
    final store = await _stores.storeFor(near);
    final key = '${query.toLowerCase()}|$limit|$store';
    final cached = _searches.remove(key);
    final products =
        cached ?? _forgottenOnFailure(key, _fetch(query, store, limit));
    _remember(key, products);
    return products;
  }

  Future<List<RetailerProduct>> _fetch(
    String query,
    String store,
    int limit,
  ) async {
    final json = await _occ.post('/products/search', {
      'query': query,
      'storeCode': store,
      'pageSize': '$limit',
      'currentPage': '0',
      'fields': listFields,
    }, const {});
    final listed = PnpCatalogueParser.products(json, store).take(limit);
    return _contents.withContents(listed.toList());
  }

  void _remember(String key, Future<List<RetailerProduct>> search) {
    _searches[key] = search;
    while (_searches.length > _recentSearchLimit) {
      _searches.remove(_searches.keys.first);
    }
  }

  /// A search that fails is forgotten, so asking again asks PnP again.
  Future<List<RetailerProduct>> _forgottenOnFailure(
    String key,
    Future<List<RetailerProduct>> search,
  ) async {
    try {
      return await search;
    } on Object {
      _forgetSearch(key);
      rethrow;
    }
  }

  // Not awaited: what it held is the future that just failed.
  void _forgetSearch(String key) => _searches.remove(key);
}
