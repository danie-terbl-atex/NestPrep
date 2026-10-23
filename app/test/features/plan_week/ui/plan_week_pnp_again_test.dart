import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/add_to_checkers/model/cart_push_result.dart';
import 'package:nestprep/features/groceries/model/grocery_item.dart';
import 'package:nestprep/features/groceries/model/product_match.dart';
import 'package:nestprep/features/plan_week/model/lunch_week_reply.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/cart_push_copy.dart';
import 'package:nestprep/shared/money/money.dart';

import '../../../support/household_fixtures.dart';
import '../../../support/plan_week_pnp_fixture.dart';

/// A week with nothing new, and the cart reached again from the brief
/// (lunch-box ADR-0027): step 4 never ends on a button that cannot be
/// pressed, and Pick n Pay items already on the list can go to the cart
/// without planning again.
void main() {
  late PlanWeekPnpFixture f;

  setUp(() => f = PlanWeekPnpFixture());
  tearDown(() => f.close());

  void nothingNew() => f.builder.reply = LunchWeekReply(
    lunches: [],
    boxesPerPack: {},
    budgetCents: 30000,
    dropped: 0,
    callsLeft: 11,
  );

  GroceryItem listed(
    String id,
    String name, {
    String? quantity,
    ProductRetailer retailer = ProductRetailer.pickNPay,
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
      productId: retailer == ProductRetailer.pickNPay
          ? PlanWeekPnpFixture.yoghurtCode
          : 'a' * 24,
      articleCode: '539078',
      unitOfMeasure: 'EA',
      name: name,
      price: const Money(3499),
      pickedBy: Fixtures.samMemberId,
    ),
  );

  testWidgets('a week with nothing new says why and leads back to the brief', (
    tester,
  ) async {
    nothingNew();
    await f.pump(tester);
    await f.run(tester, last: 'plan-week-search');
    expect(
      find.text(PlanWeekAgainCopy.nothingNewBody(ProductRetailer.pickNPay)),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('plan-week-use')), findsNothing);
    await f.tapKey(tester, 'plan-week-to-brief');
    expect(find.byKey(const ValueKey('plan-week-ideas')), findsOneWidget);
    expect(find.byKey(const ValueKey('plan-week-list-cart')), findsOneWidget);
  });

  testWidgets('nothing new survives dark at 200% on a 360-wide phone', (
    tester,
  ) async {
    nothingNew();
    await f.pump(
      tester,
      brightness: Brightness.dark,
      scale: 2,
      size: const Size(360, 800),
    );
    await f.run(tester, last: 'plan-week-search');
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text(PlanWeekAgainCopy.backToBrief), findsOneWidget);
  });

  testWidgets('the brief sends the unbought Pick n Pay items to the cart, '
      'with the packs the week wrote', (tester) async {
    f.directory.pushResult = const CartPushResult(
      added: [],
      skipped: [],
      cartItemCount: 4,
      cartTotal: Money(13996),
    );
    await f.pump(tester);
    await f.tapKey(tester, 'plan-week-shop-pickNPay');
    await f.tapThenList(
      tester,
      'plan-week-list-cart-push',
      items: [
        listed('pnp-1', 'Yoghurt', quantity: PlanWeekCopy.packs(3)),
        listed('pnp-2', 'Crackers', quantity: 'a big box'),
        listed('bought', 'Biltong', quantity: '1 pack', isBought: true),
        listed('checkers', 'Apples', retailer: ProductRetailer.checkers),
      ],
    );
    final pushed = f.directory.pushes.single;
    expect(pushed.itemIds.toSet(), {'pnp-1', 'pnp-2'});
    expect(pushed.quantities, {'pnp-1': 3, 'pnp-2': 1});
    expect(
      find.text(CartPushCopy.finishIn(ProductRetailer.pickNPay)),
      findsOneWidget,
    );
  });

  testWidgets('with nothing waiting, it says so and pushes nothing', (
    tester,
  ) async {
    await f.pump(tester);
    await f.tapKey(tester, 'plan-week-shop-pickNPay');
    await f.tapThenList(
      tester,
      'plan-week-list-cart-push',
      items: [listed('checkers', 'Apples', retailer: ProductRetailer.checkers)],
    );
    expect(f.directory.pushes, isEmpty);
    expect(
      find.text(PlanWeekAgainCopy.listCartNone(ProductRetailer.pickNPay)),
      findsOneWidget,
    );
  });

  testWidgets('at Checkers, or with the switch off, the brief offers no PnP '
      'cart', (tester) async {
    await f.pump(tester);
    expect(find.byKey(const ValueKey('plan-week-list-cart')), findsNothing);
  });
}
