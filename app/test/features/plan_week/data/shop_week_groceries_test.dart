import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/add_to_checkers/model/retailer_product.dart';
import 'package:nestprep/features/groceries/model/grocery_item.dart';
import 'package:nestprep/features/groceries/model/product_match.dart';
import 'package:nestprep/features/plan_week/data/shop_week_groceries.dart';
import 'package:nestprep/features/plan_week/model/shop_list_entry.dart';
import 'package:nestprep/shared/money/money.dart';

import '../../../support/fake_grocery_repository.dart';
import '../../../support/household_fixtures.dart';

RetailerProduct pnp(String id, {String name = 'Mini Cheddars 6 x 33g'}) =>
    RetailerProduct(
      retailer: ProductRetailer.pickNPay,
      id: id,
      storeId: 'GC13',
      articleCode: id.split('_').first,
      unitOfMeasure: 'EA',
      isSoldByWeight: false,
      name: name,
      price: const Money(4899),
      isOnPromotion: false,
      isInStock: true,
    );

ProductMatch matchOf(ProductRetailer retailer, String productId) =>
    ProductMatch(
      retailer: retailer,
      productId: productId,
      articleCode: 'a',
      unitOfMeasure: 'EA',
      name: 'old pick',
      price: const Money(100),
      pickedBy: Fixtures.samMemberId,
    );

GroceryItem onTheList(String id, String name, {ProductMatch? match}) =>
    GroceryItem(
      id: id,
      name: name,
      addedBy: Fixtures.samMemberId,
      productMatch: match,
    );

/// Where a used week's basket lands (lunch-box ADR-0026 §6, groceries
/// ADR-0007): a new line arrives with its pick in one write, and a line
/// already on the list is made to carry this week's product — the one that
/// was checked against the children's rules — before it is pushed.
void main() {
  late FakeGroceryRepository groceries;
  late ShopWeekGroceries writer;

  setUp(() {
    groceries = FakeGroceryRepository();
    writer = ShopWeekGroceries(
      groceryRepository: groceries,
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
    );
  });

  Future<List<ShopListEntry>> addWith(
    List<GroceryItem> list,
    List<ShopListLine> lines,
  ) async {
    final adding = writer.add(lines);
    await pumpEventQueue();
    groceries.emitItems(list);
    return adding;
  }

  ShopListLine line(RetailerProduct product, {String? name, int packs = 1}) => (
    product: product,
    name: name ?? 'Mini Cheddars',
    quantity: '1 pack',
    packs: packs,
  );

  test('a new line is added with its pick in one write', () async {
    final entries = await addWith(const [], [
      line(pnp('000000000000539078_EA')),
    ]);
    expect(
      groceries.addedMatched.single.match.retailer,
      ProductRetailer.pickNPay,
    );
    expect(groceries.matchesSet, isEmpty, reason: 'no second write to forget');
    expect(entries.single.isNew, isTrue);
  });

  for (final (label, oldMatch) in [
    ('a Checkers pick', matchOf(ProductRetailer.checkers, 'c' * 24)),
    ('no pick', null),
    ('another PnP product', matchOf(ProductRetailer.pickNPay, '1_EA')),
  ]) {
    test(
      'a line already on the list with $label gets this week’s product',
      () async {
        final entries = await addWith(
          [onTheList('i1', 'Mini Cheddars', match: oldMatch)],
          [line(pnp('000000000000539078_EA'))],
        );
        expect(groceries.addedMatched, isEmpty);
        final set = groceries.matchesSet.single;
        expect(set.itemId, 'i1');
        expect(set.match.retailer, ProductRetailer.pickNPay);
        expect(set.match.productId, '000000000000539078_EA');
        expect(entries.single.isNew, isFalse);
      },
    );
  }

  test('a line already carrying this week’s product is left alone', () async {
    await addWith(
      [
        onTheList(
          'i1',
          'Mini Cheddars',
          match: matchOf(ProductRetailer.pickNPay, '000000000000539078_EA'),
        ),
      ],
      [line(pnp('000000000000539078_EA'))],
    );
    expect(groceries.matchesSet, isEmpty);
    expect(groceries.addedMatched, isEmpty);
  });

  group('packs for the push', () {
    test('two lines on one item add up', () {
      const entries = [
        ShopListEntry(itemId: 'i1', name: 'Wraps', packs: 2, isNew: true),
        ShopListEntry(itemId: 'i1', name: 'Wraps', packs: 3, isNew: false),
        ShopListEntry(itemId: 'i2', name: 'Apples', packs: 1, isNew: true),
      ];
      expect(ShopListEntry.packsByItem(entries), {'i1': 5, 'i2': 1});
    });

    test('stay within what the server takes', () {
      const entries = [
        ShopListEntry(itemId: 'i1', name: 'Wraps', packs: 20, isNew: true),
        ShopListEntry(itemId: 'i1', name: 'Wraps', packs: 20, isNew: false),
        ShopListEntry(itemId: 'i2', name: 'Apples', packs: 0, isNew: true),
      ];
      expect(ShopListEntry.packsByItem(entries), {
        'i1': ShopListEntry.maxPacks,
        'i2': 1,
      });
    });
  });
}
