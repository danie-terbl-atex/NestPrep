import 'dart:async';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../../add_to_checkers/data/retailer_catalogue.dart';
import '../../add_to_checkers/model/retailer_product.dart';
import '../../add_to_checkers/model/retailer_shelf.dart';
import '../../live_location/model/coordinates.dart';
import '../model/woolworths_store.dart';
import 'woolworths_catalogue_parser.dart';
import 'woolworths_contents_reader.dart';
import 'woolworths_store_finder.dart';
import 'woolworths_web_client.dart';

/// Woolworths' catalogue over HTTPS, unauthenticated (add-to-woolworths
/// ADR-0002): the store and price list `validatePlace` gives the point, then
/// a Constructor search or browse group stocked at that store, then each
/// product's contents from its detail.
///
/// Kind to Woolworths as the other catalogues are to their shops: the store
/// for a place, each detail and the last few searches are remembered for the
/// run, a search already in flight is shared, and a 429 stops every call
/// until its `Retry-After` has passed.
final class HttpWoolworthsCatalogue implements RetailerCatalogue {
  HttpWoolworthsCatalogue({http.Client? client, DateTime Function()? now})
    : this.over(WoolworthsWebClient(client: client, now: now));

  HttpWoolworthsCatalogue.over(WoolworthsWebClient web)
    : _web = web,
      _stores = WoolworthsStoreFinder(web),
      _contents = WoolworthsContentsReader(web),
      _clientId = _sessionClientId();

  static const searchHost = 'wpkmgeuco-zone.cnstrc.com';

  /// Constructor's public browser key, the one the website sends.
  static const searchKey = 'key_tw9hKe0fkfgEf36D';
  static const _recentSearchLimit = 40;

  final WoolworthsWebClient _web;
  final WoolworthsStoreFinder _stores;
  final WoolworthsContentsReader _contents;
  final String _clientId;

  // Insertion-ordered, so the oldest search is the first to be forgotten.
  final _searches = <String, Future<List<RetailerProduct>>>{};

  @override
  Future<List<RetailerProduct>> search({
    required String query,
    required Coordinates near,
    int limit = RetailerCatalogue.defaultLimit,
  }) {
    final words = query.trim();
    return _products(
      key: 'search|${words.toLowerCase()}',
      near: near,
      limit: limit,
      uri: (store) => Uri(
        scheme: 'https',
        host: searchHost,
        pathSegments: ['v1', 'search', words],
        queryParameters: {
          'key': searchKey,
          'i': _clientId,
          's': '1',
          'num_results_per_page': '$limit',
          'page': '1',
          'filters[visibility]': const ['all', 'web and app'],
          'filters[stocked_at]': store.id,
          'us': ['default', 'jda_${store.id}'],
        },
      ),
    );
  }

  /// Best sellers first.
  @override
  Future<List<RetailerProduct>> shelf({
    required RetailerShelf shelf,
    required Coordinates near,
    int limit = RetailerCatalogue.defaultLimit,
  }) => switch (shelf.kind) {
    RetailerShelfKind.woolworthsGroup => _products(
      key: 'group|${shelf.within ?? ''}|${shelf.id}',
      near: near,
      limit: limit,
      uri: (store) => Uri(
        scheme: 'https',
        host: searchHost,
        pathSegments: ['browse', 'group_id', shelf.within ?? shelf.id],
        queryParameters: {
          'key': searchKey,
          'i': _clientId,
          's': '1',
          'sort_by': 'salerank',
          'sort_order': 'descending',
          'num_results_per_page': '$limit',
          'filters[stocked_at]': store.id,
          if (shelf.within != null) 'filters[group_id]': shelf.id,
        },
      ),
    ),
    RetailerShelfKind.productList ||
    RetailerShelfKind.displayCategory ||
    RetailerShelfKind.pnpCategory => throw ArgumentError.value(shelf.id),
  };

  Future<List<RetailerProduct>> _products({
    required String key,
    required Coordinates near,
    required int limit,
    required Uri Function(WoolworthsStore store) uri,
  }) async {
    final store = await _stores.storeFor(near);
    final cacheKey = '$key|$limit|${store.id}|${store.priceZone}';
    final cached = _searches.remove(cacheKey);
    final products =
        cached ??
        _forgottenOnFailure(cacheKey, _fetch(uri(store), store, limit));
    _remember(cacheKey, products);
    return products;
  }

  Future<List<RetailerProduct>> _fetch(
    Uri uri,
    WoolworthsStore store,
    int limit,
  ) async {
    final listed = WoolworthsCatalogueParser.products(
      await _web.get(uri),
      store,
    ).take(limit);
    return _contents.withContents(listed.toList());
  }

  void _remember(String key, Future<List<RetailerProduct>> search) {
    _searches[key] = search;
    while (_searches.length > _recentSearchLimit) {
      _searches.remove(_searches.keys.first);
    }
  }

  Future<List<RetailerProduct>> _forgottenOnFailure(
    String key,
    Future<List<RetailerProduct>> search,
  ) async {
    try {
      return await search;
    } on Object {
      _forget(key);
      rethrow;
    }
  }

  // Not awaited: what it held is the future that just failed.
  void _forget(String key) => _searches.remove(key);

  /// Constructor's visitor id: random for each run of the app, so it
  /// identifies nobody across runs.
  static String _sessionClientId() {
    final random = Random.secure();
    final bytes = [for (var i = 0; i < 16; i++) random.nextInt(256)];
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}
