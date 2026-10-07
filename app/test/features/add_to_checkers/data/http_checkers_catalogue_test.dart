import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nestprep/features/add_to_checkers/data/http_checkers_catalogue.dart';
import 'package:nestprep/features/add_to_checkers/model/checkers_area.dart';
import 'package:nestprep/features/add_to_checkers/model/checkers_shelf.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

String fixture(String name) => File(
  'test/features/add_to_checkers/fixtures/$name.json',
).readAsStringSync();

/// A Sixty60 catalogue on the far side of a fake network, counting calls.
final class FakeSixty60 {
  final requests = <http.Request>[];
  int storeStatus = 200;
  String storeBody = fixture('store_contexts_cape_town');
  int searchStatus = 200;
  Map<String, String> searchHeaders = const {};

  int callsTo(String path) =>
      requests.where((request) => request.url.path == path).length;

  late final client = MockClient((request) async {
    requests.add(request);
    if (request.url.path == HttpCheckersCatalogue.storeContextsPath) {
      return http.Response(storeBody, storeStatus);
    }
    return http.Response(
      fixture('products_filter_milk'),
      searchStatus,
      headers: searchHeaders,
    );
  });
}

void main() {
  final capeTown = CheckersArea.capeTown.centre;
  late FakeSixty60 sixty60;
  late DateTime now;
  late HttpCheckersCatalogue catalogue;

  setUp(() {
    sixty60 = FakeSixty60();
    now = DateTime.utc(2026, 9, 30, 12);
    catalogue = HttpCheckersCatalogue(client: sixty60.client, now: () => now);
  });

  test('asks for the stores, then searches at the one-hour ones', () async {
    final products = await catalogue.search(query: ' milk ', near: capeTown);

    expect(products, hasLength(5));
    expect(sixty60.requests.first.url.path, '/api/v3/store-contexts');
    expect(jsonDecode(sixty60.requests.first.body), {
      'latitude': -33.9249,
      'longitude': 18.4241,
    });
    final search = sixty60.requests.last;
    expect(search.url.path, '/api/v3/products/filter');
    expect(search.url.queryParameters['includePromotions'], 'true');
    expect(search.headers['content-type'], startsWith('application/json'));
    final body = jsonDecode(search.body) as Map<String, Object?>;
    expect(body['filter'], {
      'showAllDisplayVariants': false,
      'showNotRangedProducts': false,
      'productListSource': {'search': 'milk'},
      'paginationOptions': {'page': 0, 'pageSize': 5},
    });
    final stores =
        (body['userContext']! as Map<String, Object?>)['storeContexts']!
            as List<Object?>;
    expect(stores, hasLength(2));
  });

  test('a shelf is read by its source, best sellers first', () async {
    const list = CheckersShelf.productList('69d4ebed9cccb04862bcb67f');
    const category = CheckersShelf.displayCategory('67075e37ff987811364007b9');

    await catalogue.shelf(shelf: list, near: capeTown, limit: 24);
    await catalogue.shelf(shelf: category, near: capeTown, limit: 24);
    await catalogue.shelf(shelf: list, near: capeTown, limit: 24);

    final bodies = [
      for (final request in sixty60.requests)
        if (request.url.path == HttpCheckersCatalogue.productsPath)
          (jsonDecode(request.body) as Map<String, Object?>)['filter'],
    ];
    expect(bodies, [
      {
        'showAllDisplayVariants': false,
        'showNotRangedProducts': false,
        'productListSource': {
          'productList': {'id': '69d4ebed9cccb04862bcb67f'},
        },
        'paginationOptions': {'page': 0, 'pageSize': 24},
        'sortOptions': {'field': 'globalRateOfSale', 'direction': -1},
      },
      {
        'showAllDisplayVariants': false,
        'showNotRangedProducts': false,
        'productListSource': {
          'displayCategory': {'id': '67075e37ff987811364007b9'},
        },
        'paginationOptions': {'page': 0, 'pageSize': 24},
        'sortOptions': {'field': 'globalRateOfSale', 'direction': -1},
      },
    ]);
  });

  test('the stores for a place and a repeated search are asked once', () async {
    await catalogue.search(query: 'milk', near: capeTown);
    await catalogue.search(query: 'Milk', near: capeTown);
    await catalogue.search(query: 'bread', near: capeTown);

    expect(sixty60.callsTo(HttpCheckersCatalogue.storeContextsPath), 1);
    expect(sixty60.callsTo(HttpCheckersCatalogue.productsPath), 2);
  });

  test('no one-hour store near there is said as such', () async {
    sixty60.storeBody = '{"items": []}';
    await expectLater(
      catalogue.search(query: 'milk', near: capeTown),
      throwsA(_problem(CheckersProblem.noStoreNearby)),
    );
    expect(sixty60.callsTo(HttpCheckersCatalogue.productsPath), 0);
  });

  test('a 429 stops every call until Retry-After has passed', () async {
    sixty60
      ..searchStatus = 429
      ..searchHeaders = const {'retry-after': '20'};
    await expectLater(
      catalogue.search(query: 'milk', near: capeTown),
      throwsA(_problem(CheckersProblem.catalogueBusy)),
    );
    sixty60.searchStatus = 200;
    await expectLater(
      catalogue.search(query: 'eggs', near: capeTown),
      throwsA(_problem(CheckersProblem.catalogueBusy)),
    );
    expect(sixty60.callsTo(HttpCheckersCatalogue.productsPath), 1);

    now = now.add(const Duration(seconds: 21));
    expect(await catalogue.search(query: 'eggs', near: capeTown), isNotEmpty);
  });

  test(
    'a failed search is not remembered, so trying again asks again',
    () async {
      sixty60.searchStatus = 503;
      await expectLater(
        catalogue.search(query: 'milk', near: capeTown),
        throwsA(_problem(CheckersProblem.catalogueUnreachable)),
      );
      sixty60.searchStatus = 200;
      expect(
        await catalogue.search(query: 'milk', near: capeTown),
        hasLength(5),
      );
    },
  );

  test('a failed store lookup is not remembered either', () async {
    sixty60.storeStatus = 500;
    await expectLater(
      catalogue.search(query: 'milk', near: capeTown),
      throwsA(_problem(CheckersProblem.catalogueUnreachable)),
    );
    sixty60.storeStatus = 200;
    expect(await catalogue.search(query: 'milk', near: capeTown), hasLength(5));
  });

  test('a catalogue that never answers times out as unreachable', () async {
    final hanging = HttpCheckersCatalogue(
      client: MockClient((_) => Completer<http.Response>().future),
      timeout: const Duration(milliseconds: 10),
    );
    await expectLater(
      hanging.search(query: 'milk', near: capeTown),
      throwsA(_problem(CheckersProblem.catalogueUnreachable)),
    );
  });

  test('a body that is not JSON is "Checkers changed"', () async {
    sixty60.storeBody = '<html>';
    await expectLater(
      catalogue.search(query: 'milk', near: capeTown),
      throwsA(_problem(CheckersProblem.catalogueChanged)),
    );
  });
}

Matcher _problem(CheckersProblem problem) => isA<CheckersFailure>().having(
  (failure) => failure.problem,
  'problem',
  problem,
);
