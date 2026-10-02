import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/app_log.dart';
import '../../live_location/model/coordinates.dart';
import '../model/checkers_product.dart';
import '../model/checkers_shelf.dart';
import '../model/checkers_store.dart';
import 'checkers_catalogue.dart';
import 'checkers_catalogue_parser.dart';

/// The Sixty60 catalogue over HTTPS, unauthenticated — the two calls
/// `checkers-discovery/probe-search.mjs` proved on 2026-09-30: the stores that
/// serve a point, then a search at those stores — or, the same call with
/// another source, a shelf (proved 2026-10-01, lunch-box ADR-0013).
///
/// Kind to Checkers on purpose: each call has a timeout (`BE-19`), the stores
/// for a place and the last few searches are remembered for as long as the
/// app runs, a search already in flight is shared rather than repeated, and a
/// 429 stops every call until its `Retry-After` has passed.
final class HttpCheckersCatalogue implements CheckersCatalogue {
  HttpCheckersCatalogue({
    http.Client? client,
    DateTime Function()? now,
    this.timeout = const Duration(seconds: 8),
  }) : _client = client ?? http.Client(),
       _now = now ?? DateTime.now,
       _deviceId = _sessionDeviceId();

  static const host = 'catalog.sixty60.co.za';
  static const storeContextsPath = '/api/v3/store-contexts';
  static const productsPath = '/api/v3/products/filter';
  static const _recentSearchLimit = 40;
  static const _defaultCoolDown = Duration(seconds: 30);

  final http.Client _client;
  final DateTime Function() _now;
  final Duration timeout;
  final String _deviceId;

  final _stores = <String, Future<List<CheckersStore>>>{};
  // Insertion-ordered, so the oldest search is the first to be forgotten.
  final _searches = <String, Future<List<CheckersProduct>>>{};
  DateTime? _coolDownUntil;

  @override
  Future<List<CheckersProduct>> search({
    required String query,
    required Coordinates near,
    int limit = CheckersCatalogue.defaultLimit,
  }) {
    final words = query.trim();
    return _products(
      key: 'search|${words.toLowerCase()}',
      source: {'search': words},
      near: near,
      limit: limit,
    );
  }

  /// A shelf in the order the catalogue says sells best: its default order
  /// changes from one identical call to the next.
  @override
  Future<List<CheckersProduct>> shelf({
    required CheckersShelf shelf,
    required Coordinates near,
    int limit = CheckersCatalogue.defaultLimit,
  }) => _products(
    key: '${shelf.kind.name}|${shelf.id}',
    source: switch (shelf.kind) {
      CheckersShelfKind.productList => {
        'productList': {'id': shelf.id},
      },
      CheckersShelfKind.displayCategory => {
        'displayCategory': {'id': shelf.id},
      },
    },
    near: near,
    limit: limit,
    sort: const {'field': 'globalRateOfSale', 'direction': -1},
  );

  Future<List<CheckersProduct>> _products({
    required String key,
    required Map<String, Object?> source,
    required Coordinates near,
    required int limit,
    Map<String, Object?>? sort,
  }) async {
    final stores = await _storesFor(near);
    if (stores.isEmpty) {
      throw const CheckersFailure(CheckersProblem.noStoreNearby);
    }
    final cacheKey = [
      key,
      limit,
      for (final store in stores) store.storeId,
    ].join('|');
    final cached = _searches.remove(cacheKey);
    final products = cached ?? _fetchProducts(source, sort, stores, limit);
    _remember(cacheKey, products);
    return products;
  }

  Future<List<CheckersStore>> _storesFor(Coordinates near) {
    // About a kilometre: the same stores serve the whole of it.
    final key =
        '${near.latitude.toStringAsFixed(2)},'
        '${near.longitude.toStringAsFixed(2)}';
    final cached = _stores[key];
    if (cached != null) return cached;
    final fetch = _fetchStores(near);
    _stores[key] = fetch;
    // A failed lookup is not remembered, so the next search asks again.
    unawaited(
      fetch.then<void>(
        (_) {},
        onError: (Object _) {
          _stores.remove(key);
        },
      ),
    );
    return fetch;
  }

  Future<List<CheckersStore>> _fetchStores(Coordinates near) async {
    final json = await _post(Uri.https(host, storeContextsPath), {
      'latitude': near.latitude,
      'longitude': near.longitude,
    });
    return CheckersCatalogueParser.sixtyMinuteStores(json);
  }

  Future<List<CheckersProduct>> _fetchProducts(
    Map<String, Object?> source,
    Map<String, Object?>? sort,
    List<CheckersStore> stores,
    int limit,
  ) async {
    final json = await _post(
      Uri.https(host, productsPath, const {
        'isCarousel': 'false',
        'includePromotions': 'true',
        'promotionChannel': 'sixty60',
      }),
      {
        'filter': {
          'showAllDisplayVariants': false,
          'showNotRangedProducts': false,
          'productListSource': source,
          'paginationOptions': {'page': 0, 'pageSize': limit},
          'sortOptions': ?sort,
        },
        'userContext': {
          'storeContexts': [for (final store in stores) _storeJson(store)],
        },
      },
    );
    return CheckersCatalogueParser.products(json).take(limit).toList();
  }

  void _remember(String key, Future<List<CheckersProduct>> search) {
    _searches[key] = search;
    unawaited(
      search.then<void>(
        (_) {},
        onError: (Object _) {
          _searches.remove(key);
        },
      ),
    );
    while (_searches.length > _recentSearchLimit) {
      _searches.remove(_searches.keys.first);
    }
  }

  Future<Object?> _post(Uri uri, Map<String, Object?> body) async {
    final coolDownUntil = _coolDownUntil;
    if (coolDownUntil != null && _now().isBefore(coolDownUntil)) {
      throw const CheckersFailure(CheckersProblem.catalogueBusy);
    }
    final http.Response response;
    try {
      response = await _client
          .post(uri, headers: _headers(), body: jsonEncode(body))
          .timeout(timeout);
    } on TimeoutException catch (error) {
      throw _unreachable('timeout', error);
    } on http.ClientException catch (error) {
      throw _unreachable('client', error);
    }
    return _decode(response);
  }

  Object? _decode(http.Response response) {
    final status = response.statusCode;
    if (status == 429) {
      _coolDownUntil = _now().add(_retryAfter(response));
      AppLog.failure('checkers catalogue', code: '429');
      throw const CheckersFailure(CheckersProblem.catalogueBusy);
    }
    if (status < 200 || status >= 300) {
      throw _unreachable('$status', null);
    }
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException catch (error) {
      AppLog.failure('checkers catalogue', code: 'not-json', error: error);
      throw const CheckersFailure(CheckersProblem.catalogueChanged);
    }
  }

  Duration _retryAfter(http.Response response) {
    final seconds = int.tryParse(response.headers['retry-after'] ?? '');
    return seconds == null || seconds <= 0
        ? _defaultCoolDown
        : Duration(seconds: seconds);
  }

  CheckersFailure _unreachable(String code, Object? error) {
    AppLog.failure('checkers catalogue', code: code, error: error);
    return const CheckersFailure(CheckersProblem.catalogueUnreachable);
  }

  /// What the Sixty60 app sends that this call can honestly send too. Only
  /// `content-type` is required today; a bearer from Checkers' non-user
  /// bootstrap token would be added here if search ever needs one.
  Map<String, String> _headers() => {
    'content-type': 'application/json',
    'accept': 'application/json',
    'channel': 'super-app',
    'device-id': _deviceId,
  };

  static Map<String, Object?> _storeJson(CheckersStore store) => {
    'storeId': store.storeId,
    'serviceOptionIds': store.serviceOptionIds,
    'hasCapacity': store.hasCapacity,
    'brandPriority': ?store.brandPriority,
  };

  /// Random for each run of the app, so it identifies nobody across runs.
  static String _sessionDeviceId() {
    final random = Random.secure();
    return [for (var i = 0; i < 16; i++) random.nextInt(256).toRadixString(16)]
        .map((byte) => byte.padLeft(2, '0'))
        .join();
  }
}
