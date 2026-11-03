import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/add_to_checkers/data/checkers_place_resolver.dart';
import 'package:nestprep/features/add_to_checkers/data/retailer_catalogues.dart';
import 'package:nestprep/features/basket_compare/model/basket_comparison.dart';
import 'package:nestprep/features/basket_compare/state/basket_compare_controller.dart';
import 'package:nestprep/features/groceries/model/grocery_item.dart';
import 'package:nestprep/features/groceries/model/product_match.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/copy/plan_week_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/money/money.dart';

import '../../../support/checkers_grocery_harness.dart';
import '../../../support/fake_checkers.dart';
import '../../../support/fake_grocery_repository.dart';
import '../../../support/fake_live_location.dart';
import '../../../support/fake_plan_week.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/plan_week_pnp_fixture.dart';

const checkers = ProductRetailer.checkers;
const pnp = ProductRetailer.pickNPay;

GroceryItem item(
  String name, {
  String? quantity,
  ProductMatch? productMatch,
  String? boughtBy,
}) => GroceryItem(
  id: 'id-$name',
  name: name,
  quantity: quantity,
  addedBy: Fixtures.samMemberId,
  productMatch: productMatch,
  boughtBy: boughtBy,
);

void main() {
  late FakeShopCatalogue checkersShop;
  late FakeShopCatalogue pnpShop;
  late FakeGroceryRepository groceries;
  late FakeProductMatchRanker ranker;
  late BasketCompareController controller;

  BasketCompareController build({bool withRanker = true}) =>
      BasketCompareController(
        catalogues: RetailerCatalogues(
          checkers: checkersShop,
          pickNPay: pnpShop,
        ),
        placeResolver: CheckersPlaceResolver(
          locationSource: FakeLocationSource(),
          areaPreference: FakeCheckersAreaPreference(),
        ),
        groceryRepository: groceries,
        householdId: Fixtures.householdId,
        memberId: Fixtures.thandiMemberId,
        shops: const [checkers, pnp],
        ranker: withRanker ? ranker : null,
      );

  setUp(() {
    checkersShop = FakeShopCatalogue();
    pnpShop = FakeShopCatalogue();
    groceries = FakeGroceryRepository();
    ranker = FakeProductMatchRanker();
    controller = build();
  });
  tearDown(() => controller.dispose());

  Future<BasketComparison> compare(List<GroceryItem> items) async {
    controller.start();
    groceries.emitItems(items);
    await pumpEventQueue();
    return switch (controller.comparison) {
      AsyncData(:final value) => value,
      final other => throw StateError('not compared: $other'),
    };
  }

  ShopLine? lineFor(String name, ProductRetailer shop) =>
      switch (controller.comparison) {
        AsyncData(:final value) =>
          value.items
              .firstWhere((compared) => compared.item.name == name)
              .lines[shop],
        _ => null,
      };

  test('loads until the list is read, then asks each shop per item', () async {
    controller.start();
    expect(controller.comparison, isA<AsyncLoading<BasketComparison>>());
    groceries.emitItems([item('milk'), item('eggs', boughtBy: 'm-sam')]);
    await pumpEventQueue();
    final comparison =
        (controller.comparison as AsyncData<BasketComparison>).value;
    expect(comparison.items.map((compared) => compared.item.name), ['milk']);
    expect(checkersShop.queries, ['milk']);
    expect(pnpShop.queries, ['milk']);
    expect(controller.place, isNotNull);
    expect(comparison.isComplete, isTrue);
  });

  test('start is idempotent', () async {
    controller
      ..start()
      ..start();
    groceries.emitItems([item('milk')]);
    await pumpEventQueue();
    expect(checkersShop.queries, ['milk']);
  });

  test('an empty to-buy list is compared at once', () async {
    final comparison = await compare(const []);
    expect(comparison.items, isEmpty);
    expect(comparison.isComplete, isTrue);
  });

  test('a list that cannot be read fails, and retry starts over', () async {
    controller.start();
    groceries.failItemsWith(const PermissionDeniedFailure());
    await pumpEventQueue();
    expect(
      controller.comparison,
      isA<AsyncFailure<BasketComparison>>().having(
        (state) => state.failure,
        'failure',
        isA<PermissionDeniedFailure>(),
      ),
    );
    controller.retry();
    expect(controller.comparison, isA<AsyncLoading<BasketComparison>>());
    groceries.emitItems([item('milk')]);
    await pumpEventQueue();
    expect(controller.comparison, isA<AsyncData<BasketComparison>>());
  });

  test('the member\'s own pick, still returned, is priced live', () async {
    checkersShop.byQuery['milk'] = [
      checkersProduct('Other milk', id: 'other', cents: 1000),
      checkersProduct('Clover milk', id: pickedMilk.productId, cents: 4199),
    ];
    await compare([item('milk', productMatch: pickedMilk)]);
    final line = lineFor('milk', checkers)! as ShopOffer;
    expect(line.source, ShopOfferSource.picked);
    expect(line.unitPrice, const Money(4199));
    expect(line.product?.id, pickedMilk.productId);
    expect(ranker.asked, isEmpty);
  });

  test('a pick no longer returned stands at its picked price', () async {
    checkersShop.byQuery['milk'] = [checkersProduct('Other milk', id: 'other')];
    await compare([item('milk', productMatch: pickedMilk)]);
    final line = lineFor('milk', checkers)! as ShopOffer;
    expect(line.source, ShopOfferSource.pickedEarlier);
    expect(line.unitPrice, pickedMilk.price);
    expect(line.name, pickedMilk.name);
    expect(line.product, isNull);
  });

  test('a pick at one shop does not decide the other', () async {
    pnpShop.byQuery['milk'] = [pnpProduct('PnP milk', code: 'pnp-milk')];
    ranker.fits = {'pnp-milk': 0.9};
    await compare([item('milk', productMatch: pickedMilk)]);
    final line = lineFor('milk', pnp)! as ShopOffer;
    expect(line.source, ShopOfferSource.matched);
    expect(line.product?.id, 'pnp-milk');
  });

  test('Jev\'s best at 0.6 or above is the match', () async {
    checkersShop.byQuery['milk'] = [
      checkersProduct('Milk A', id: 'a'),
      checkersProduct('Milk B', id: 'b', cents: 2599),
    ];
    ranker.fits = {'a': 0.5, 'b': 0.8};
    await compare([item('milk')]);
    final line = lineFor('milk', checkers)! as ShopOffer;
    expect(line.source, ShopOfferSource.matched);
    expect(line.product?.id, 'b');
    expect(line.unitPrice, const Money(2599));
  });

  test('nothing at 0.6 is not found', () async {
    checkersShop.byQuery['milk'] = [checkersProduct('Milk A', id: 'a')];
    ranker.fits = {'a': 0.59};
    await compare([item('milk')]);
    expect(
      lineFor('milk', checkers),
      isA<ShopMiss>().having(
        (m) => m.reason,
        'reason',
        ShopMissReason.notFound,
      ),
    );
  });

  test('when Jev cannot rank, the first in-stock product stands in', () async {
    checkersShop.byQuery['milk'] = [
      checkersProduct('Gone', id: 'gone', isInStock: false),
      checkersProduct('Milk A', id: 'a'),
      checkersProduct('Milk B', id: 'b'),
    ];
    ranker.failure = const UnavailableFailure();
    await compare([item('milk')]);
    final line = lineFor('milk', checkers)! as ShopOffer;
    expect(line.source, ShopOfferSource.closest);
    expect(line.product?.id, 'a');
  });

  test('with no ranker, the first in-stock product stands in', () async {
    controller.dispose();
    controller = build(withRanker: false);
    checkersShop.byQuery['milk'] = [checkersProduct('Milk A', id: 'a')];
    await compare([item('milk')]);
    expect(
      (lineFor('milk', checkers)! as ShopOffer).source,
      ShopOfferSource.closest,
    );
  });

  test('weighed products are dropped before ranking', () async {
    checkersShop.byQuery['mince'] = [
      checkersProduct('Loose mince', id: 'kg', unitOfMeasure: 'KG'),
      checkersProduct('Mince 500g', id: 'pack'),
    ];
    ranker.fits = {'kg': 1, 'pack': 0.7};
    await compare([item('mince')]);
    expect(ranker.asked.first.productIds, ['pack']);
    expect((lineFor('mince', checkers)! as ShopOffer).product?.id, 'pack');
  });

  test(
    'only weighed or nothing is not found; only out of stock says so',
    () async {
      checkersShop.byQuery['mince'] = [
        checkersProduct('Loose mince', id: 'kg', unitOfMeasure: 'KG'),
      ];
      checkersShop.byQuery['eggs'] = [
        checkersProduct('Eggs', id: 'eggs', isInStock: false),
      ];
      await compare([item('mince'), item('eggs'), item('saffron')]);
      ShopMissReason? reason(String name) => switch (lineFor(name, checkers)) {
        ShopMiss(:final reason) => reason,
        _ => null,
      };
      expect(reason('mince'), ShopMissReason.notFound);
      expect(reason('eggs'), ShopMissReason.outOfStock);
      expect(reason('saffron'), ShopMissReason.notFound);
      expect(ranker.asked, isEmpty);
    },
  );

  test('packs come from the quantity Plan my week wrote', () async {
    checkersShop.byQuery['yoghurt'] = [
      checkersProduct('Yoghurt', id: 'y', cents: 1500),
    ];
    ranker.fits = {'y': 0.9};
    final comparison = await compare([
      item('yoghurt', quantity: PlanWeekCopy.packs(3)),
    ]);
    expect(comparison.items.single.packs, 3);
    final line = lineFor('yoghurt', checkers)! as ShopOffer;
    expect(line.packs, 3);
    expect(line.total, const Money(4500));
  });

  test('a shop that cannot be searched is unreachable until retried', () async {
    pnpShop.failFor['milk'] = const UnavailableFailure();
    pnpShop.byQuery['bread'] = [pnpProduct('Bread', code: 'bread')];
    ranker.fits = {'bread': 0.9};
    final comparison = await compare([item('milk'), item('bread')]);
    expect(lineFor('milk', pnp), isA<ShopUnreachable>());
    expect(comparison.hasUnreachable, isTrue);

    pnpShop.failFor.clear();
    pnpShop.byQuery['milk'] = [pnpProduct('Milk', code: 'milk')];
    ranker.fits = {'milk': 0.9};
    pnpShop.queries.clear();
    checkersShop.queries.clear();
    controller.retry();
    expect(lineFor('milk', pnp), isNull);
    await pumpEventQueue();
    expect(pnpShop.queries, ['milk']);
    expect(checkersShop.queries, isEmpty);
    expect(lineFor('milk', pnp), isA<ShopOffer>());
  });

  test(
    'a pick whose shop cannot be searched stands at its picked price',
    () async {
      checkersShop.failFor['milk'] = const UnavailableFailure();
      await compare([item('milk', productMatch: pickedMilk)]);
      expect(
        (lineFor('milk', checkers)! as ShopOffer).source,
        ShopOfferSource.pickedEarlier,
      );
    },
  );

  test('at most three searches are in flight at each shop', () async {
    final gate = Completer<void>();
    checkersShop.gate = gate;
    pnpShop.gate = gate;
    controller.start();
    groceries.emitItems([for (var n = 0; n < 10; n++) item('thing $n')]);
    await pumpEventQueue();
    expect(checkersShop.queries, hasLength(3));
    expect(pnpShop.queries, hasLength(3));
    gate.complete();
    await pumpEventQueue();
    expect(checkersShop.queries, hasLength(10));
    expect(pnpShop.queries, hasLength(10));
    expect(
      (controller.comparison as AsyncData<BasketComparison>).value.isComplete,
      isTrue,
    );
  });

  test('only the first forty unbought items are compared', () async {
    final comparison = await compare([
      for (var n = 0; n < 45; n++) item('thing $n'),
    ]);
    expect(comparison.items, hasLength(BasketCompareController.itemLimit));
    expect(controller.leftOut, 5);
  });

  group('useShop', () {
    setUp(() {
      checkersShop
        ..byQuery['milk'] = [
          checkersProduct('Clover milk', id: pickedMilk.productId),
        ]
        ..byQuery['bread'] = [checkersProduct('Bread', id: 'bread')]
        ..byQuery['eggs'] = [checkersProduct('Eggs', id: 'eggs')];
      pnpShop
        ..byQuery['milk'] = [pnpProduct('PnP milk', code: 'pnp-milk')]
        ..byQuery['bread'] = [pnpProduct('PnP bread', code: 'pnp-bread')];
      ranker.fits = {
        'bread': 0.9,
        'eggs': 0.9,
        'pnp-milk': 0.9,
        'pnp-bread': 0.9,
      };
    });

    List<GroceryItem> list() => [
      item('milk', productMatch: pickedMilk),
      item('bread'),
      item('eggs'),
      item('juice', productMatch: pickedMilk.copyWith(productId: 'gone')),
    ];

    test('writes only the matches that differ, and counts them', () async {
      await compare(list());
      expect(controller.matchesWrittenBy(checkers), 2);
      expect(controller.picksReplacedBy(checkers), 0);
      expect(controller.matchesWrittenBy(pnp), 2);
      expect(controller.picksReplacedBy(pnp), 1);

      expect(await controller.useShop(checkers), isTrue);
      expect(
        groceries.matchesSet.map((set) => (set.itemId, set.match.productId)),
        unorderedEquals([('id-bread', 'bread'), ('id-eggs', 'eggs')]),
      );
      expect(groceries.matchesSet.map((set) => set.match.pickedBy).toSet(), {
        Fixtures.thandiMemberId,
      });
      expect(controller.matchesWrittenBy(checkers), 0);
      expect(controller.isApplying, isFalse);
    });

    test('items the shop lacks keep their match', () async {
      await compare(list());
      expect(await controller.useShop(pnp), isTrue);
      expect(
        groceries.matchesSet.map((set) => set.itemId),
        unorderedEquals(['id-milk', 'id-bread']),
      );
      expect(controller.picksReplacedBy(pnp), 0);
    });

    test('a refused write is held and answers false', () async {
      await compare(list());
      groceries.failWritesWith = const PermissionDeniedFailure();
      expect(await controller.useShop(checkers), isFalse);
      expect(controller.actionFailure, isA<PermissionDeniedFailure>());
      expect(controller.matchesWrittenBy(checkers), 2);
    });
  });

  test('answers after dispose are ignored', () async {
    final gate = Completer<void>();
    checkersShop.gate = gate;
    controller.start();
    groceries.emitItems([item('milk')]);
    await pumpEventQueue();
    controller.dispose();
    gate.complete();
    await pumpEventQueue();
    controller = build();
  });

  test('a list read after dispose is ignored', () async {
    controller.start();
    controller.dispose();
    groceries.emitItems([item('milk')]);
    await pumpEventQueue();
    expect(checkersShop.queries, isEmpty);
    controller = build();
  });
}
