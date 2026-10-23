import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/add_to_checkers/data/checkers_place_resolver.dart';
import 'package:nestprep/features/add_to_checkers/data/retailer_catalogue.dart';
import 'package:nestprep/features/add_to_checkers/data/retailer_catalogues.dart';
import 'package:nestprep/features/add_to_checkers/model/checkers_area.dart';
import 'package:nestprep/features/add_to_checkers/model/retailer_product.dart';
import 'package:nestprep/features/add_to_checkers/model/retailer_shelf.dart';
import 'package:nestprep/features/groceries/model/grocery_item.dart';
import 'package:nestprep/features/groceries/model/product_match.dart';
import 'package:nestprep/features/live_location/model/coordinates.dart';
import 'package:nestprep/features/plan_week/data/shop_week_groceries.dart';
import 'package:nestprep/features/recipes/data/recipe_groceries.dart';
import 'package:nestprep/features/recipes/model/recipe_shop_line.dart';
import 'package:nestprep/features/recipes/state/recipe_shop_controller.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_checkers.dart';
import '../../../support/fake_grocery_repository.dart';
import '../../../support/fake_live_location.dart';
import '../../../support/household_fixtures.dart';

/// A shop that answers each query from [answers], in the order asked.
final class _ScriptedCatalogue implements RetailerCatalogue {
  _ScriptedCatalogue(this.answers);

  final Map<String, List<RetailerProduct>> answers;
  final failing = <String>{};
  final asked = <String>[];

  @override
  Future<List<RetailerProduct>> search({
    required String query,
    required Coordinates near,
    int limit = RetailerCatalogue.defaultLimit,
  }) async {
    asked.add(query);
    if (failing.contains(query)) throw const UnavailableFailure();
    return answers[query] ?? const [];
  }

  @override
  Future<List<RetailerProduct>> shelf({
    required RetailerShelf shelf,
    required Coordinates near,
    int limit = RetailerCatalogue.defaultLimit,
  }) async => const [];
}

/// *Add to grocer* (recipes ADR-0005): each ingredient not ticked off,
/// searched in turn at the chosen shop, Jev's best first, then onto the one
/// grocery list — matched where the shop had it, by name where it did not,
/// and never twice.
void main() {
  late _ScriptedCatalogue checkers;
  late _ScriptedCatalogue pnp;
  late FakeProductMatchRanker ranker;
  late FakeGroceryRepository groceries;
  late RecipeShopController controller;

  const lines = [
    RecipeShopLine(index: 0, name: 'Beef mince', quantity: '1 kg'),
    RecipeShopLine(index: 2, name: 'Onions', quantity: '2'),
    RecipeShopLine(index: 5, name: 'Bay leaves', quantity: null),
  ];

  setUp(() {
    checkers = _ScriptedCatalogue({
      'Beef mince': [
        checkersProduct('Beef mince 500g', id: 'm1', cents: 6999),
        checkersProduct('Lean beef mince 1kg', id: 'm2', cents: 12999),
      ],
      'Onions': [checkersProduct('Onions 1kg', id: 'o1', cents: 2299)],
    });
    pnp = _ScriptedCatalogue({});
    ranker = FakeProductMatchRanker()..fits = const {'m2': 0.9, 'm1': 0.4};
    groceries = FakeGroceryRepository();
    final areas = FakeCheckersAreaPreference()
      ..chosen[Fixtures.householdId] = CheckersArea.fallback;
    controller = RecipeShopController(
      catalogues: RetailerCatalogues(checkers: checkers, pickNPay: pnp),
      placeResolver: CheckersPlaceResolver(
        locationSource: FakeLocationSource(),
        areaPreference: areas,
      ),
      groceries: RecipeGroceries(
        groceryRepository: groceries,
        matched: ShopWeekGroceries(
          groceryRepository: groceries,
          householdId: Fixtures.householdId,
          memberId: Fixtures.samMemberId,
        ),
        householdId: Fixtures.householdId,
        memberId: Fixtures.samMemberId,
      ),
      householdId: Fixtures.householdId,
      ranker: ranker,
    );
  });

  tearDown(() async {
    controller.dispose();
    await groceries.close();
  });

  /// Adds, answering each read of the list with [list].
  Future<bool> addWith(List<GroceryItem> list) async {
    final adding = controller.addToList();
    for (var i = 0; i < 4; i++) {
      await pumpEventQueue();
      groceries.emitItems(list);
    }
    return adding;
  }

  test('searches each line in turn and chooses Jev’s best', () async {
    await controller.start(shop: ProductRetailer.checkers, lines: lines);

    expect(checkers.asked, ['Beef mince', 'Onions', 'Bay leaves']);
    expect(pnp.asked, isEmpty);
    expect(controller.isSettled, isTrue);
    final mince = controller.lines.first;
    expect(mince.chosen?.id, 'm2');
    expect(mince.isBestMatch, isTrue);
    expect(mince.products.first.id, 'm2', reason: 'the best leads the list');
    expect(controller.lines[2].search, RecipeShopSearch.notFound);
    expect(controller.estimate?.cents, 12999 + 2299);
  });

  test('a ranker that fails leaves the shop’s order', () async {
    ranker.failure = const UnavailableFailure();

    await controller.start(shop: ProductRetailer.checkers, lines: lines);

    expect(controller.lines.first.chosen?.id, 'm1');
    expect(controller.lines.first.isBestMatch, isFalse);
  });

  test('one failed search fails that line only', () async {
    checkers.failing.add('Onions');

    await controller.start(shop: ProductRetailer.checkers, lines: lines);

    expect(controller.lines[1].search, RecipeShopSearch.failed);
    expect(controller.lines.first.search, RecipeShopSearch.found);
  });

  test('matched lines go on with their product, the rest by name', () async {
    await controller.start(shop: ProductRetailer.checkers, lines: lines);

    expect(await addWith(const []), isTrue);

    expect(
      [for (final added in groceries.addedMatched) added.name],
      ['Beef mince', 'Onions'],
    );
    expect(groceries.addedMatched.first.match.productId, 'm2');
    expect(groceries.added.first.quantity, '1 kg');
    expect(groceries.added.last.name, 'Bay leaves');
    expect(controller.addedCount, 3);
    expect(controller.listed, hasLength(2), reason: 'what a cart push names');
  });

  test(
    'a line left off, or already waiting on the list, is not added',
    () async {
      await controller.start(shop: ProductRetailer.checkers, lines: lines);
      controller.toggle(2);

      await addWith([
        const GroceryItem(
          id: 'i1',
          name: 'bay leaves',
          addedBy: Fixtures.samMemberId,
        ),
      ]);

      expect(
        [for (final added in groceries.added) added.name],
        ['Beef mince'],
        reason: 'onions were left off; bay leaves are on the list already',
      );
      expect(controller.addedCount, 1);
    },
  );

  test('a different product chosen is the one that goes on', () async {
    await controller.start(shop: ProductRetailer.checkers, lines: lines);
    final cheaper = controller.lines.first.products.last;
    controller.choose(0, cheaper);

    await addWith(const []);

    expect(groceries.addedMatched.first.match.productId, cheaper.id);
  });

  test('another shop searches the same lines again, keeping what was left '
      'off', () async {
    await controller.start(shop: ProductRetailer.checkers, lines: lines);
    controller.toggle(0);

    await controller.chooseShop(ProductRetailer.pickNPay);

    expect(pnp.asked, ['Beef mince', 'Onions', 'Bay leaves']);
    expect(controller.shop, ProductRetailer.pickNPay);
    expect(controller.lines.first.isIncluded, isFalse);
  });

  test('a refused write is held for the sheet to say', () async {
    await controller.start(shop: ProductRetailer.checkers, lines: lines);
    groceries.failWritesWith = const PermissionDeniedFailure();

    expect(await addWith(const []), isFalse);

    expect(controller.actionFailure, isA<PermissionDeniedFailure>());
    expect(controller.listed, isNull);
  });
}
