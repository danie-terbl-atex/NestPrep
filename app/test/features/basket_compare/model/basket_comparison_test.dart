import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/basket_compare/model/basket_comparison.dart';
import 'package:nestprep/features/groceries/model/grocery_item.dart';
import 'package:nestprep/features/groceries/model/product_match.dart';
import 'package:nestprep/shared/money/money.dart';

const checkers = ProductRetailer.checkers;
const pnp = ProductRetailer.pickNPay;
const both = [checkers, pnp];

ShopOffer offer(ProductRetailer shop, int cents, {int packs = 1}) => ShopOffer(
  shop: shop,
  name: 'product',
  unitPrice: Money(cents),
  packs: packs,
  source: ShopOfferSource.matched,
);

ShopMiss miss(ProductRetailer shop) =>
    ShopMiss(shop: shop, reason: ShopMissReason.notFound);

ItemComparison compared(String id, List<ShopLine> lines, {int packs = 1}) =>
    lines.fold(
      ItemComparison(
        item: GroceryItem(id: id, name: id, addedBy: 'm'),
        packs: packs,
      ),
      (item, line) => item.withLine(line),
    );

void main() {
  test('an offer\'s total is its unit price times its packs', () {
    expect(offer(checkers, 1250, packs: 3).total, const Money(3750));
  });

  test('totals sum what each shop has, and count what it lacks', () {
    final comparison = BasketComparison(
      shops: both,
      items: [
        compared('milk', [offer(checkers, 3000), offer(pnp, 3200)]),
        compared('bread', [offer(checkers, 2000), miss(pnp)]),
        compared('eggs', [const ShopUnreachable(checkers), offer(pnp, 5000)]),
      ],
    );
    final [atCheckers, atPnp] = comparison.totals;
    expect(atCheckers.shop, checkers);
    expect(atCheckers.total, const Money(5000));
    expect(atCheckers.found, 2);
    expect(atCheckers.missing, 1);
    expect(atPnp.total, const Money(8200));
    expect(atPnp.found, 2);
    expect(atPnp.missing, 1);
    expect(comparison.everywhere.map((item) => item.item.id), ['milk']);
    expect(comparison.notEverywhere.map((item) => item.item.id), [
      'bread',
      'eggs',
    ]);
    expect(comparison.hasUnreachable, isTrue);
  });

  test('the cheapest shop is decided on the items every shop has', () {
    final comparison = BasketComparison(
      shops: both,
      items: [
        compared('milk', [offer(checkers, 3000), offer(pnp, 3200)]),
        compared('cheese', [offer(checkers, 9000), offer(pnp, 8000)]),
        compared('bread', [miss(checkers), offer(pnp, 100)]),
      ],
    );
    final [atCheckers, atPnp] = comparison.totals;
    expect(atCheckers.likeForLike, const Money(12000));
    expect(atPnp.likeForLike, const Money(11200));
    expect(atPnp.total, const Money(11300));
    expect(comparison.cheapest?.shop, pnp);
    expect(comparison.saving, const Money(800));
    expect(comparison.splitTotal, const Money(11000));
  });

  test('a tie, or nothing at every shop, has no cheapest and no saving', () {
    final tied = BasketComparison(
      shops: both,
      items: [
        compared('milk', [offer(checkers, 3000), offer(pnp, 3000)]),
      ],
    );
    expect(tied.cheapest, isNull);
    expect(tied.saving, const Money.zero());

    final nowhere = BasketComparison(
      shops: both,
      items: [
        compared('milk', [offer(checkers, 3000), miss(pnp)]),
      ],
    );
    expect(nowhere.cheapest, isNull);
    expect(nowhere.splitTotal, const Money.zero());
  });

  test('one shop compared has no cheapest', () {
    final comparison = BasketComparison(
      shops: const [checkers],
      items: [
        compared('milk', [offer(checkers, 3000)]),
      ],
    );
    expect(comparison.cheapest, isNull);
    expect(comparison.saving, const Money.zero());
  });

  test('an item counts once every shop has answered for it', () {
    final comparison = BasketComparison(
      shops: both,
      items: [
        compared('milk', [offer(checkers, 3000), offer(pnp, 3200)]),
        compared('bread', [offer(checkers, 2000)]),
        compared('eggs', const []),
      ],
    );
    expect(comparison.settledCount, 1);
    expect(comparison.isComplete, isFalse);
    expect(comparison.totals.first.total, const Money(3000));
    expect(comparison.notEverywhere, isEmpty);

    const done = BasketComparison(shops: both, items: []);
    expect(done.isComplete, isTrue);
  });

  test('per item, the cheapest shop is the lower total; a tie is none', () {
    expect(
      compared('milk', [
        offer(checkers, 1000, packs: 3),
        offer(pnp, 2500),
      ]).cheapestOf(both),
      pnp,
    );
    expect(
      compared('milk', [
        offer(checkers, 1000),
        offer(pnp, 1000),
      ]).cheapestOf(both),
      isNull,
    );
    expect(
      compared('milk', [offer(checkers, 1000), miss(pnp)]).cheapestOf(both),
      isNull,
    );
  });
}
