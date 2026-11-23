import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/add_to_checkers/data/checkers_place_resolver.dart';
import 'package:nestprep/features/add_to_checkers/data/retailer_catalogues.dart';
import 'package:nestprep/features/add_to_checkers/state/list_match_controller.dart';
import 'package:nestprep/features/add_to_checkers/state/product_finder.dart';
import 'package:nestprep/features/groceries/model/grocery_item.dart';
import 'package:nestprep/features/groceries/model/product_match.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/money/money.dart';

import '../../../support/fake_checkers.dart';
import '../../../support/fake_grocery_repository.dart';
import '../../../support/fake_live_location.dart';
import '../../../support/household_fixtures.dart';

GroceryItem item(String name, String id) =>
    GroceryItem(id: id, name: name, addedBy: Fixtures.samMemberId);

final class Harness {
  Harness({int items = 3}) {
    controller = ListMatchController(
      finder: ProductFinder(
        catalogues: RetailerCatalogues({ProductRetailer.checkers: catalogue}),
        placeResolver: CheckersPlaceResolver(
          locationSource: FakeLocationSource(),
          areaPreference: FakeCheckersAreaPreference(),
        ),
        householdId: Fixtures.householdId,
        ranker: ranker,
      ),
      groceryRepository: groceries,
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
      shop: ProductRetailer.checkers,
      items: [for (var i = 0; i < items; i++) item('item $i', 'i$i')],
    );
    addTearDown(controller.dispose);
  }

  final catalogue = FakeCheckersCatalogue()
    ..products = [
      checkersProduct('Milk A', id: 'a'),
      checkersProduct('Milk B', id: 'b', cents: 2000),
      checkersProduct('Milk C', id: 'c', isInStock: false),
    ];
  final groceries = FakeGroceryRepository();
  final ranker = FakeProductMatchRanker();
  late final ListMatchController controller;

  List<String> get shown => switch (controller.products) {
    AsyncData(:final value) => [for (final product in value) product.id],
    _ => const [],
  };
}

void main() {
  test('nothing is selected when Jev is not sure', () async {
    final h = Harness();
    await pumpEventQueue();
    expect(h.shown, ['a', 'b', 'c']);
    expect(h.controller.selected, isNull);
    expect(h.controller.bestMatchId, isNull);
  });

  test('Jev\'s best is first and selected already', () async {
    final h = Harness()..ranker.fits = {'b': 0.9, 'a': 0.2};
    await pumpEventQueue();
    expect(h.shown.first, 'b');
    expect(h.controller.selected?.id, 'b');
    expect(h.controller.bestMatchId, 'b');
  });

  test('a best match a cart cannot take is not selected', () async {
    final h = Harness()..ranker.fits = {'c': 0.9};
    await pumpEventQueue();
    expect(h.controller.bestMatchId, 'c');
    expect(h.controller.selected, isNull);
  });

  test('a second tap unselects', () async {
    final h = Harness();
    await pumpEventQueue();
    final product = h.catalogue.products.first;
    h.controller.select(product);
    expect(h.controller.selected, product);
    h.controller.select(product);
    expect(h.controller.selected, isNull);
  });

  test('Next writes the pick and moves on', () async {
    final h = Harness();
    await pumpEventQueue();
    h.controller
      ..select(h.catalogue.products[1])
      ..next();
    expect(h.controller.index, 1);
    await pumpEventQueue();
    final written = h.groceries.matchesSet.single;
    expect(written.itemId, 'i0');
    expect(written.match.productId, 'b');
    expect(written.match.pickedBy, Fixtures.samMemberId);
    expect(h.controller.pickedCount, 1);
    expect(h.controller.estimate, const Money(2000));
  });

  test('a price by the kilogram is left out of the estimate', () async {
    final h = Harness()
      ..catalogue.products = [
        checkersProduct('Mince', id: 'kg', unitOfMeasure: 'KG'),
      ];
    await pumpEventQueue();
    h.controller
      ..select(h.catalogue.products.single)
      ..next();
    await pumpEventQueue();
    expect(h.controller.pickedCount, 1);
    expect(h.controller.estimate, isNull);
  });

  test('Next without a selection does nothing', () async {
    final h = Harness();
    await pumpEventQueue();
    h.controller.next();
    expect(h.controller.index, 0);
    expect(h.groceries.matchesSet, isEmpty);
  });

  test('Skip writes nothing and moves on', () async {
    final h = Harness();
    await pumpEventQueue();
    h.controller.skip();
    await pumpEventQueue();
    expect(h.controller.index, 1);
    expect(h.controller.skippedCount, 1);
    expect(h.groceries.matchesSet, isEmpty);
    expect(h.groceries.removed, isEmpty);
  });

  test('Remove only marks the item, and stepping back can keep it', () async {
    final h = Harness();
    await pumpEventQueue();
    h.controller.remove();
    await pumpEventQueue();
    expect(h.controller.index, 1);
    expect([for (final item in h.controller.removed) item.id], ['i0']);
    expect(h.groceries.removed, isEmpty);

    h.controller.back();
    await pumpEventQueue();
    expect(h.controller.outcome, ListMatchOutcome.removed);
    h.controller.keep();
    await pumpEventQueue();
    expect(h.controller.outcome, ListMatchOutcome.waiting);
    expect(h.controller.removed, isEmpty);
  });

  test('stepping back shows what was picked, and the same pick is not '
      'written twice', () async {
    final h = Harness();
    await pumpEventQueue();
    h.controller
      ..select(h.catalogue.products.first)
      ..next();
    await pumpEventQueue();
    h.controller.back();
    await pumpEventQueue();
    expect(h.controller.selected?.id, 'a');
    h.controller.next();
    await pumpEventQueue();
    expect(h.groceries.matchesSet, hasLength(1));
  });

  test('a refused write takes the pick back and says so', () async {
    final h = Harness();
    await pumpEventQueue();
    h.groceries.failWritesWith = const PermissionDeniedFailure();
    h.controller
      ..select(h.catalogue.products.first)
      ..next();
    await pumpEventQueue();
    expect(h.controller.actionFailure, isA<PermissionDeniedFailure>());
    expect(h.controller.pickedCount, 0);
    expect(h.controller.estimate, isNull);
  });

  test('the next item is looked for while this one is read, and each name '
      'is asked of the shop once', () async {
    final h = Harness();
    await pumpEventQueue();
    expect(
      [for (final search in h.catalogue.searches) search.query],
      ['item 0', 'item 1'],
    );
    h.controller.skip();
    await pumpEventQueue();
    expect(
      [for (final search in h.catalogue.searches) search.query],
      ['item 0', 'item 1', 'item 2'],
    );
  });

  test('a search that fails is a failure with a retry', () async {
    final h = Harness()
      ..catalogue.failWith = const CheckersFailure(
        CheckersProblem.catalogueBusy,
      );
    await pumpEventQueue();
    expect(h.controller.products, isA<AsyncFailure<Object?>>());
    h.catalogue.failWith = null;
    h.controller.retry();
    await pumpEventQueue();
    expect(h.shown, ['a', 'b', 'c']);
  });

  test('after the last item it is done, with what it came to', () async {
    final h = Harness(items: 2);
    await pumpEventQueue();
    h.controller
      ..select(h.catalogue.products.first)
      ..next();
    await pumpEventQueue();
    h.controller.remove();
    await pumpEventQueue();
    expect(h.controller.isDone, isTrue);
    expect(h.controller.item, isNull);
    expect(h.controller.pickedCount, 1);
    expect(h.controller.removedCount, 1);
    h.controller.back();
    await pumpEventQueue();
    expect(h.controller.isDone, isFalse);
    expect(h.controller.item?.id, 'i1');
  });
}
