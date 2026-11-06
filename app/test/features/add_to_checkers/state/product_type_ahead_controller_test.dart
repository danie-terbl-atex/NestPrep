import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/add_to_checkers/data/checkers_place_resolver.dart';
import 'package:nestprep/features/add_to_checkers/data/retailer_catalogues.dart';
import 'package:nestprep/features/add_to_checkers/state/product_finder.dart';
import 'package:nestprep/features/add_to_checkers/state/product_type_ahead_controller.dart';
import 'package:nestprep/features/groceries/model/product_match.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_checkers.dart';
import '../../../support/fake_live_location.dart';
import '../../../support/fake_plan_week.dart';
import '../../../support/household_fixtures.dart';

const debounce = Duration(milliseconds: 40);
const checkers = ProductRetailer.checkers;
const pickNPay = ProductRetailer.pickNPay;

Future<void> settle() async {
  await Future<void>.delayed(const Duration(milliseconds: 60));
  await pumpEventQueue();
}

final class Harness {
  Harness() {
    addTearDown(controller.dispose);
  }

  final catalogue = FakeCheckersCatalogue()
    ..products = [
      checkersProduct('Clover Fresh Full Cream Milk 2L'),
      checkersProduct(
        'Darling Fresh Full Cream Milk 2L',
        id: '5db2b6a9280e5b57ebe9a222',
      ),
    ];
  final pnp = FakeShopCatalogue();
  final ranker = FakeProductMatchRanker();

  late final controller = ProductTypeAheadController(
    finder: ProductFinder(
      catalogues: RetailerCatalogues({
        ProductRetailer.checkers: catalogue,
        ProductRetailer.pickNPay: pnp,
      }),
      placeResolver: CheckersPlaceResolver(
        locationSource: FakeLocationSource(),
        areaPreference: FakeCheckersAreaPreference(),
      ),
      householdId: Fixtures.householdId,
      ranker: ranker,
    ),
    debounce: debounce,
  );

  List<String> get shownIds => switch (controller.products) {
    AsyncData(value: final products) => [for (final p in products) p.id],
    _ => const [],
  };
}

void main() {
  test('typing in a row asks only once, for what it settled on', () async {
    final h = Harness();
    h.controller
      ..lookUp('mil', shop: checkers)
      ..lookUp('milk', shop: checkers);
    expect(h.controller.products, isA<AsyncLoading<Object?>>());
    await settle();

    expect(h.catalogue.searches.map((s) => s.query), ['milk']);
    expect(h.controller.query, (text: 'milk', shop: checkers));
    expect(h.shownIds, hasLength(2));
  });

  test('fewer than three letters, or blank, clears without asking', () async {
    final h = Harness();
    h.controller.lookUp('milk', shop: checkers);
    await settle();
    h.controller.lookUp('  m ', shop: checkers);

    expect(h.controller.query, isNull);
    expect(h.catalogue.searches, hasLength(1));
  });

  test('an answer for text that has gone is dropped', () async {
    final h = Harness();
    final gate = h.catalogue.gate = Completer<void>();
    h.controller.lookUp('milk', shop: checkers);
    await settle();
    h.controller.clear();
    gate.complete();
    await settle();

    expect(h.controller.query, isNull);
    expect(h.controller.products, isA<AsyncLoading<Object?>>());
  });

  test("Jev's best goes first and is called the best", () async {
    final h = Harness()
      ..ranker.fits = {
        '5d3af63bf434cf8420737dd6': 0.2,
        '5db2b6a9280e5b57ebe9a222': 0.9,
      };
    h.controller.lookUp('milk', shop: checkers);
    await settle();

    expect(h.shownIds.first, '5db2b6a9280e5b57ebe9a222');
    expect(h.controller.bestMatchId, '5db2b6a9280e5b57ebe9a222');
  });

  test('ranking that fails keeps the shop order and says nothing', () async {
    final h = Harness()
      ..ranker.failure = const CheckersFailure(CheckersProblem.catalogueBusy);
    h.controller.lookUp('milk', shop: checkers);
    await settle();

    expect(h.shownIds.first, '5d3af63bf434cf8420737dd6');
    expect(h.controller.bestMatchId, isNull);
  });

  test('typing back over a word does not ask again', () async {
    final h = Harness();
    h.controller.lookUp('milk', shop: checkers);
    await settle();
    h.controller.lookUp('milks', shop: checkers);
    await settle();
    h.controller.lookUp('Milk ', shop: checkers);
    await settle();

    expect(h.catalogue.searches.map((s) => s.query), ['milk', 'milks']);
    expect(h.shownIds, hasLength(2));
  });

  test('the same name at the other shop asks that shop', () async {
    final h = Harness();
    h.controller.lookUp('milk', shop: checkers);
    await settle();
    h.controller.lookUp('milk', shop: pickNPay);
    await settle();

    expect(h.pnp.queries, ['milk']);
    expect(h.controller.query?.shop, pickNPay);
  });

  test('a shop failure is shown, and retry asks again', () async {
    final h = Harness()
      ..catalogue.failWith = const CheckersFailure(
        CheckersProblem.catalogueBusy,
      );
    h.controller.lookUp('milk', shop: checkers);
    await settle();
    expect(h.controller.products, isA<AsyncFailure<Object?>>());

    h.catalogue.failWith = null;
    h.controller.retry();
    await settle();
    expect(h.shownIds, hasLength(2));
    expect(h.catalogue.searches, hasLength(2));
  });
}
