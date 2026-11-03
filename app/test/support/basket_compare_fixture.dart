import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/basket_compare/model/basket_comparison.dart';
import 'package:nestprep/features/groceries/model/grocery_item.dart';
import 'package:nestprep/features/groceries/model/product_match.dart';
import 'package:nestprep/shared/copy/basket_compare_copy.dart';
import 'package:nestprep/shared/money/money.dart';

import 'household_fixtures.dart';

const checkers = ProductRetailer.checkers;
const pnp = ProductRetailer.pickNPay;
const bothShops = [checkers, pnp];

GroceryItem listItem(String name) =>
    GroceryItem(id: 'id-$name', name: name, addedBy: Fixtures.samMemberId);

ShopOffer offer(
  ProductRetailer shop,
  String name,
  int cents, {
  int packs = 1,
  ShopOfferSource source = ShopOfferSource.matched,
  int? oldCents,
}) => ShopOffer(
  shop: shop,
  name: name,
  unitPrice: Money(cents),
  oldPrice: oldCents == null ? null : Money(oldCents),
  isOnPromotion: oldCents != null,
  packs: packs,
  source: source,
);

ItemComparison compared(String name, List<ShopLine> lines, {int packs = 1}) =>
    ItemComparison(
      item: listItem(name),
      packs: packs,
      lines: {for (final line in lines) line.shop: line},
    );

/// Pick n Pay cheapest like for like by R1.00, a split R2.00 under that, and
/// every kind of line: a promotion, a pick priced when it was picked, a
/// closest match, a product one shop lacks, one out of stock, a shop that
/// could not be reached, and a shop still being asked.
BasketComparison mixedComparison() => BasketComparison(
  shops: bothShops,
  items: [
    compared('Milk', [
      offer(
        checkers,
        'Clover Fresh Full Cream Milk 2L',
        3799,
        source: ShopOfferSource.picked,
      ),
      offer(pnp, 'PnP Full Cream Milk 2L', 3499, oldCents: 3999),
    ]),
    compared('Bread', packs: 2, [
      offer(checkers, 'Albany Superior White Bread 700g', 1899, packs: 2),
      offer(
        pnp,
        'Sasko Premium White Bread 700g',
        1999,
        packs: 2,
        source: ShopOfferSource.pickedEarlier,
      ),
    ]),
    compared('Hummus', [
      offer(
        checkers,
        'Woolies-style Roasted Red Pepper Hummus 250g',
        4599,
        source: ShopOfferSource.closest,
      ),
      const ShopMiss(shop: pnp, reason: ShopMissReason.notFound),
    ]),
    compared('Greek yoghurt', [
      const ShopMiss(shop: checkers, reason: ShopMissReason.outOfStock),
      offer(pnp, 'Clover Greek Style Yoghurt 1kg', 4599),
    ]),
    compared('Eggs', [
      const ShopUnreachable(checkers),
      offer(pnp, 'PnP Large Free Range Eggs 18', 5299),
    ]),
    compared('Mature cheddar, the sharp one the children like', [
      offer(checkers, 'Clover Mature Cheddar Cheese Block 900g', 13999),
    ]),
  ],
);

/// The screen's frame around [body], as the route shows it.
Future<void> pumpCompareBody(
  WidgetTester tester,
  Widget body, {
  Brightness brightness = Brightness.light,
  double scale = 1,
}) {
  final nest = brightness == Brightness.dark
      ? NestTheme.dark()
      : NestTheme.light();
  return tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: nestThemeData(nest),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child ?? const SizedBox.shrink(),
      ),
      home: NestScaffold(title: BasketCompareCopy.title, body: body),
    ),
  );
}

/// Lets the shops' skeletons pulse without waiting for them to stop.
Future<void> settleWithSkeletons(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}
