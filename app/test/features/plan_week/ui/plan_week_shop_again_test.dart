import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/add_to_checkers/model/cart_push_result.dart';
import 'package:nestprep/features/add_to_checkers/ui/shop_cart_links.dart';
import 'package:nestprep/features/groceries/model/grocery_item.dart';
import 'package:nestprep/features/groceries/model/product_match.dart';
import 'package:nestprep/features/plan_week/model/lunch_week_reply.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/cart_push_copy.dart';
import 'package:nestprep/shared/copy/checkers_copy.dart';
import 'package:nestprep/shared/money/money.dart';

import '../../../support/household_fixtures.dart';
import '../../../support/plan_week_shop_fixture.dart';

/// A week with nothing new, and the cart reached again from the brief
/// (lunch-box ADR-0027), at every shop alike: step 4 never ends on a button
/// that cannot be pressed, and the shop's items already on the list can go
/// to its cart without planning again.
void main() {
  void nothingNew(PlanWeekShopFixture f) => f.builder.reply = LunchWeekReply(
    lunches: [],
    boxesPerPack: {},
    budgetCents: 30000,
    dropped: 0,
    callsLeft: 11,
  );

  GroceryItem listed(
    String id,
    String name, {
    required ProductRetailer retailer,
    String? quantity,
    bool isBought = false,
  }) => GroceryItem(
    id: id,
    name: name,
    quantity: quantity,
    addedBy: Fixtures.samMemberId,
    boughtAt: isBought ? DateTime.utc(2026, 10, 12) : null,
    boughtBy: isBought ? Fixtures.samMemberId : null,
    productMatch: ProductMatch(
      retailer: retailer,
      productId: '${retailer.code}-$id',
      articleCode: '539078',
      unitOfMeasure: 'EA',
      name: name,
      price: const Money(3499),
      pickedBy: Fixtures.samMemberId,
    ),
  );

  for (final shop in ProductRetailer.values) {
    group(CheckersCopy.retailerName(shop), () {
      late PlanWeekShopFixture f;

      setUp(() => f = PlanWeekShopFixture(shop: shop));
      tearDown(() => f.close());

      testWidgets('a week with nothing new says why and leads back to the '
          'brief and its cart', (tester) async {
        nothingNew(f);
        await f.pump(tester);
        await f.run(tester, last: 'plan-week-search');
        expect(
          find.text(PlanWeekAgainCopy.nothingNewBody(shop)),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('plan-week-use')), findsNothing);
        await f.tapKey(tester, 'plan-week-to-brief');
        expect(find.byKey(const ValueKey('plan-week-ideas')), findsOneWidget);
        expect(
          find.text(PlanWeekAgainCopy.listCartAction(shop)),
          findsOneWidget,
        );
      });

      testWidgets('the brief sends the unbought items matched there to its '
          'cart, with the packs the week wrote', (tester) async {
        f.pusher.pushResult = const CartPushResult(
          added: [],
          skipped: [],
          cartItemCount: 4,
          cartTotal: Money(13996),
        );
        final other = ProductRetailer.values.firstWhere((at) => at != shop);
        await f.pump(tester);
        await f.choose(tester);
        await f.tapThenList(
          tester,
          'plan-week-list-cart-push',
          items: [
            listed(
              'mine-1',
              'Yoghurt',
              retailer: shop,
              quantity: PlanWeekCopy.packs(3),
            ),
            listed('mine-2', 'Crackers', retailer: shop, quantity: 'a big box'),
            listed(
              'bought',
              'Biltong',
              retailer: shop,
              quantity: '1 pack',
              isBought: true,
            ),
            listed('elsewhere', 'Apples', retailer: other),
          ],
        );
        final pushed = f.pusher.pushes.single;
        expect(pushed.itemIds.toSet(), {'mine-1', 'mine-2'});
        expect(
          pushed.quantities,
          takesPackQuantities(shop) ? {'mine-1': 3, 'mine-2': 1} : isEmpty,
        );
        expect(f.pushers[other]!.pushes, isEmpty);
        expect(find.text(CartPushCopy.finishIn(shop)), findsOneWidget);
      });

      testWidgets('with nothing waiting, it says so and pushes nothing', (
        tester,
      ) async {
        final other = ProductRetailer.values.firstWhere((at) => at != shop);
        await f.pump(tester);
        await f.choose(tester);
        await f.tapThenList(
          tester,
          'plan-week-list-cart-push',
          items: [listed('elsewhere', 'Apples', retailer: other)],
        );
        expect(f.pusher.pushes, isEmpty);
        expect(find.text(PlanWeekAgainCopy.listCartNone(shop)), findsOneWidget);
      });
    });
  }

  testWidgets('nothing new survives dark at 200% on a 360-wide phone', (
    tester,
  ) async {
    final f = PlanWeekShopFixture(shop: ProductRetailer.woolworths);
    addTearDown(f.close);
    nothingNew(f);
    await f.pump(
      tester,
      brightness: Brightness.dark,
      scale: 2,
      size: const Size(360, 800),
    );
    await f.run(tester, last: 'plan-week-search');
    expect(tester.takeException(), isNull);
    await tester.dragFrom(
      tester.getTopLeft(find.byType(Scrollable).first) + const Offset(24, 24),
      const Offset(0, -6000),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text(PlanWeekAgainCopy.backToBrief), findsOneWidget);
  });
}
