import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nestprep/features/add_to_checkers/model/checkers_area.dart';
import 'package:nestprep/features/add_to_checkers/model/retailer_shelf.dart';
import 'package:nestprep/features/add_to_pnp/data/http_pnp_catalogue.dart';
import 'package:nestprep/features/live_location/model/coordinates.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

String fixture(String name) =>
    File('test/features/add_to_pnp/fixtures/$name.json').readAsStringSync();

/// Pick n Pay's commerce API on the far side of a fake network.
final class FakePnp {
  final requests = <http.Request>[];
  int addressStatus = 201;
  int searchStatus = 200;
  int detailStatus = 200;
  Map<String, String> searchHeaders = const {};

  List<http.Request> to(String suffix) => [
    for (final request in requests)
      if (request.url.path.endsWith(suffix)) request,
  ];

  late final client = MockClient((request) async {
    requests.add(request);
    final path = request.url.path;
    if (request.method == 'POST' && path.endsWith('/users/anonymous/carts')) {
      return http.Response(jsonEncode({'guid': 'anon-cart'}), 201);
    }
    if (path.endsWith('/addresses/delivery')) {
      return addressStatus == 201
          ? http.Response(jsonEncode({'serviceable': true}), 201)
          : http.Response(
              jsonEncode({
                'errors': [
                  {'message': 'deliveryAddressNotServiceable'},
                ],
              }),
              addressStatus,
            );
    }
    if (request.method == 'GET' &&
        path.endsWith('/users/anonymous/carts/anon-cart')) {
      return http.Response(
        jsonEncode({
          'baseStore': {'uid': 'GC13'},
        }),
        200,
      );
    }
    if (request.method == 'DELETE') return http.Response('', 200);
    if (path.endsWith('/products/search')) {
      return http.Response(
        fixture('search_mixed'),
        searchStatus,
        headers: searchHeaders,
      );
    }
    if (path.contains('/products/')) {
      return detailStatus == 200
          ? http.Response(fixture('detail_with_contents'), 200)
          : http.Response('<html>', detailStatus);
    }
    return http.Response('', 404);
  });
}

void main() {
  const sandton = Coordinates(latitude: -26.1088, longitude: 28.0527);
  late FakePnp pnp;
  late DateTime now;
  late HttpPnpCatalogue catalogue;

  setUp(() {
    pnp = FakePnp();
    now = DateTime.utc(2026, 10, 12, 12);
    catalogue = HttpPnpCatalogue(client: pnp.client, now: () => now);
  });

  test(
    'the store comes from a throw-away anonymous cart, then is deleted',
    () async {
      await catalogue.search(query: 'chips', near: sandton);
      final address = jsonDecode(
        pnp.to('/addresses/delivery').single.body,
      ) as Map<String, Object?>;
      // Rounded to about a kilometre: PnP needs no closer than that.
      expect(address['latitude'], -26.11);
      expect(address['longitude'], 28.05);
      expect(address['town'], CheckersArea.johannesburg.label);
      expect(address['postalCode'], CheckersArea.johannesburg.postalCode);
      expect(address['streetname'], 'Main Road', reason: 'a placeholder');
      expect(
        pnp.requests.where((request) => request.method == 'DELETE'),
        hasLength(1),
      );
      final search = pnp.to('/products/search').single;
      expect(search.url.queryParameters['storeCode'], 'GC13');
      expect(search.url.queryParameters['query'], 'chips:relevance');
      expect(search.headers.keys, isNot(contains('authorization')));
    },
  );

  test('the store is remembered for the place', () async {
    await catalogue.search(query: 'chips', near: sandton);
    await catalogue.search(query: 'apples', near: sandton);
    expect(pnp.to('/addresses/delivery'), hasLength(1));
  });

  test('somewhere PnP does not deliver is no store nearby', () async {
    pnp.addressStatus = 400;
    await expectLater(
      catalogue.search(query: 'chips', near: sandton),
      throwsA(
        isA<PnpFailure>().having(
          (failure) => failure.problem,
          'problem',
          PnpProblem.noStoreNearby,
        ),
      ),
    );
    expect(
      pnp.requests.where((request) => request.method == 'DELETE'),
      hasLength(1),
      reason: 'the throw-away cart is still deleted',
    );
  });

  test('each product’s contents come from its detail, read once', () async {
    final found = await catalogue.search(
      query: 'chips',
      near: sandton,
      limit: 3,
    );
    expect(found, hasLength(3));
    expect(found.first.allergenText, contains('Gluten'));
    expect(found.first.ingredientsText, startsWith('Potatoes'));
    final details = pnp.requests.where(
      (request) => request.url.path.contains('/products/0'),
    );
    expect(details, hasLength(3));
    expect(details.first.url.queryParameters['storeCode'], 'GC13');

    await catalogue.search(query: 'crisps', near: sandton, limit: 3);
    expect(
      pnp.requests.where((request) => request.url.path.contains('/products/0')),
      hasLength(3),
      reason: 'details are national and remembered',
    );
  });

  test('a detail that cannot be read leaves the contents unknown', () async {
    pnp.detailStatus = 500;
    final found = await catalogue.search(
      query: 'chips',
      near: sandton,
      limit: 2,
    );
    expect(found, hasLength(2));
    expect(found.every((product) => !product.hasContentsText), isTrue);
  });

  test('a category is read by its code, in PnP’s own order', () async {
    await catalogue.shelf(
      shelf: const RetailerShelf.pnpCategory('lunch-box-snacks-1664414929'),
      near: sandton,
    );
    expect(
      pnp.to('/products/search').single.url.queryParameters['query'],
      ':relevance:allCategories:lunch-box-snacks-1664414929',
    );
  });

  test('a 429 holds every call until Retry-After has passed', () async {
    pnp
      ..searchStatus = 429
      ..searchHeaders = const {'retry-after': '60'};
    await expectLater(
      catalogue.search(query: 'chips', near: sandton),
      throwsA(isA<PnpFailure>()),
    );
    final calls = pnp.requests.length;
    await expectLater(
      catalogue.search(query: 'apples', near: sandton),
      throwsA(
        isA<PnpFailure>().having(
          (failure) => failure.problem,
          'problem',
          PnpProblem.catalogueBusy,
        ),
      ),
    );
    expect(pnp.requests.length, calls, reason: 'nothing was sent');
    now = now.add(const Duration(seconds: 61));
    pnp.searchStatus = 200;
    expect(await catalogue.search(query: 'apples', near: sandton), isNotEmpty);
  });
}
