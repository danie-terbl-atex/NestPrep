import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nestprep/features/add_to_checkers/model/retailer_shelf.dart';
import 'package:nestprep/features/add_to_woolworths/data/http_woolworths_catalogue.dart';
import 'package:nestprep/features/live_location/model/coordinates.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

http.Response fixture(
  String name, [
  int status = 200,
  Map<String, String> headers = const {},
]) => http.Response.bytes(
  utf8.encode(
    File('test/features/add_to_woolworths/fixtures/$name.json')
        .readAsStringSync(),
  ),
  status,
  headers: headers,
);

/// Constructor and `woolworths.co.za` on the far side of a fake network.
final class FakeWoolworths {
  final requests = <http.Request>[];
  String place = 'validate_place';
  int searchStatus = 200;
  int detailStatus = 200;
  Map<String, String> searchHeaders = const {};

  List<http.Request> to(String path) => [
    for (final request in requests)
      if (request.url.path.startsWith(path)) request,
  ];

  late final client = MockClient((request) async {
    requests.add(request);
    final path = request.url.path;
    if (path == '/server/validatePlace') {
      return fixture(place);
    }
    if (path.startsWith('/v1/search/')) {
      return fixture('search_milk', searchStatus, searchHeaders);
    }
    if (path.startsWith('/browse/group_id/')) {
      return fixture('browse_food');
    }
    if (path == '/server/getProductInfo') {
      return detailStatus == 200
          ? fixture('product_info')
          : http.Response('<html>', detailStatus);
    }
    return http.Response('', 404);
  });
}

Matcher refusedAs(WoolworthsProblem problem) => throwsA(
  isA<WoolworthsFailure>().having((f) => f.problem, 'problem', problem),
);

void main() {
  const rosebank = Coordinates(latitude: -26.14592, longitude: 28.04179);
  late FakeWoolworths woolworths;
  late DateTime now;
  late HttpWoolworthsCatalogue catalogue;

  setUp(() {
    woolworths = FakeWoolworths();
    now = DateTime.utc(2026, 11, 5, 9);
    catalogue = HttpWoolworthsCatalogue(
      client: woolworths.client,
      now: () => now,
    );
  });

  test('asks for the store near a place rounded to about a kilometre, with '
      'a Woolworths referer', () async {
    await catalogue.search(query: 'milk', near: rosebank);
    final place = woolworths.to('/server/validatePlace').single;
    expect(place.url.host, 'www.woolworths.co.za');
    expect(place.url.queryParameters, {
      'latitude': '-26.15',
      'longitude': '28.04',
    });
    expect(place.headers['referer'], 'https://www.woolworths.co.za/');
  });

  test('searches Constructor at that store, as the website does', () async {
    final products = await catalogue.search(query: ' milk ', near: rosebank);
    final search = woolworths.to('/v1/search/').single;
    expect(search.url.host, HttpWoolworthsCatalogue.searchHost);
    expect(search.url.pathSegments, ['v1', 'search', 'milk']);
    final query = search.url.queryParametersAll;
    expect(query['key'], [HttpWoolworthsCatalogue.searchKey]);
    expect(query['filters[stocked_at]'], ['475']);
    expect(query['filters[visibility]'], ['all', 'web and app']);
    expect(query['us'], ['default', 'jda_475']);
    expect(query['num_results_per_page'], ['5']);
    expect(query['i']!.single, matches(RegExp(r'^[0-9a-f-]{36}$')));
    expect(search.headers.containsKey('referer'), isFalse);
    expect(products, hasLength(5));
    expect(products.first.storeId, '475');
  });

  test('a word with a slash stays one path segment', () async {
    await catalogue.search(query: 'salt/pepper', near: rosebank);
    expect(woolworths.to('/v1/search/').single.url.pathSegments, [
      'v1',
      'search',
      'salt/pepper',
    ]);
  });

  test('fills each product’s contents from its detail, once a run', () async {
    final products = await catalogue.search(query: 'milk', near: rosebank);
    expect(products.first.ingredientsText, "Pasteurised Cow's Milk.");
    expect(products.first.allergenText, "Contains: Cow's milk.");
    final details = woolworths.to('/server/getProductInfo');
    expect(details, hasLength(5));
    expect(
      details.first.url.queryParameters['productURL'],
      '/prod/_/A-20026875',
    );

    await catalogue.search(query: 'full cream milk', near: rosebank);
    expect(woolworths.to('/server/getProductInfo'), hasLength(5));
  });

  test('a detail that cannot be read leaves the contents unknown', () async {
    woolworths.detailStatus = 503;
    final products = await catalogue.search(query: 'milk', near: rosebank);
    expect(products, hasLength(5));
    expect(products.every((product) => !product.hasContentsText), isTrue);
  });

  test(
    'remembers the store for the place and the search for the run',
    () async {
      await catalogue.search(query: 'milk', near: rosebank);
      await catalogue.search(query: 'Milk', near: rosebank);
      await catalogue.search(query: 'bread', near: rosebank);
      expect(woolworths.to('/server/validatePlace'), hasLength(1));
      expect(woolworths.to('/v1/search/'), hasLength(2));
    },
  );

  test(
    'a place nobody delivers to is said, and asked again next time',
    () async {
      woolworths.place = 'validate_place_undeliverable';
      await expectLater(
        catalogue.search(query: 'milk', near: rosebank),
        refusedAs(WoolworthsProblem.noStoreNearby),
      );
      woolworths.place = 'validate_place';
      await catalogue.search(query: 'milk', near: rosebank);
      expect(woolworths.to('/server/validatePlace'), hasLength(2));
    },
  );

  test('a 429 stops every call until Retry-After has passed', () async {
    woolworths
      ..searchStatus = 429
      ..searchHeaders = const {'retry-after': '20'};
    await expectLater(
      catalogue.search(query: 'milk', near: rosebank),
      refusedAs(WoolworthsProblem.catalogueBusy),
    );
    woolworths.searchStatus = 200;
    await expectLater(
      catalogue.search(query: 'milk', near: rosebank),
      refusedAs(WoolworthsProblem.catalogueBusy),
    );
    expect(woolworths.to('/v1/search/'), hasLength(1));
    now = now.add(const Duration(seconds: 21));
    expect(await catalogue.search(query: 'milk', near: rosebank), hasLength(5));
  });

  test('an error answer is unreachable, and not remembered', () async {
    woolworths.searchStatus = 500;
    await expectLater(
      catalogue.search(query: 'milk', near: rosebank),
      refusedAs(WoolworthsProblem.catalogueUnreachable),
    );
    woolworths.searchStatus = 200;
    expect(await catalogue.search(query: 'milk', near: rosebank), hasLength(5));
  });

  test('a shelf is a browse group by best sellers at the store', () async {
    final products = await catalogue.shelf(
      shelf: const RetailerShelf.woolworthsGroup('cat606520'),
      near: rosebank,
      limit: 10,
    );
    final browse = woolworths.to('/browse/group_id/').single;
    expect(browse.url.pathSegments, ['browse', 'group_id', 'cat606520']);
    expect(browse.url.queryParameters['sort_by'], 'salerank');
    expect(browse.url.queryParameters['sort_order'], 'descending');
    expect(browse.url.queryParameters['filters[stocked_at]'], '475');
    expect(products, hasLength(10));
    expect(browse.url.queryParameters['filters[group_id]'], isNull);
  });

  test(
    'a group inside another is that group browsed, filtered to it',
    () async {
      await catalogue.shelf(
        shelf: const RetailerShelf.woolworthsGroup(
          'cat869839',
          within: 'cat848672',
        ),
        near: rosebank,
      );
      final browse = woolworths.to('/browse/group_id/').single;
      expect(browse.url.pathSegments, ['browse', 'group_id', 'cat848672']);
      expect(browse.url.queryParameters['filters[group_id]'], 'cat869839');
    },
  );

  test('another shop’s shelf has no meaning here', () {
    expect(
      () => catalogue.shelf(
        shelf: const RetailerShelf.pnpCategory('lunch-box-snacks-1664414929'),
        near: rosebank,
      ),
      throwsArgumentError,
    );
  });
}
