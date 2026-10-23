import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/add_to_checkers/model/cart_push_result.dart';
import 'package:nestprep/features/groceries/model/product_match.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/cart_push_copy.dart';
import 'package:nestprep/shared/copy/lunch_shop_copy.dart';
import 'package:nestprep/shared/copy/pnp_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/money/money.dart';

import '../../../support/household_fixtures.dart';
import '../../../support/plan_week_pnp_fixture.dart';

/// *Plan my week* at Pick n Pay (lunch-box ADR-0026, add-to-pnp ADR-0004):
/// the brief offers the shop only with the switch on, a Pick n Pay run reads
/// Pick n Pay's shelves and search, and the done step puts the week into the
/// member's own cart — four states, in words.
void main() {
  late PlanWeekPnpFixture f;

  setUp(() => f = PlanWeekPnpFixture());
  tearDown(() => f.close());

  testWidgets('with the switch off, the brief is Checkers only', (
    tester,
  ) async {
    f.isPnpOn = false;
    await f.pump(tester);
    expect(find.byKey(const ValueKey('plan-week-shop-pickNPay')), findsNothing);
    expect(find.text(LunchShopCopy.shopOnly), findsOneWidget);
  });

  testWidgets('the brief offers both shops; choosing one is remembered', (
    tester,
  ) async {
    await f.pump(tester);
    expect(find.text(LunchShopCopy.chooseShop), findsOneWidget);
    await f.tapKey(tester, 'plan-week-shop-pickNPay');
    expect(
      find.text(LunchShopCopy.shopNear(ProductRetailer.pickNPay, 'Cape Town')),
      findsOneWidget,
    );
    expect(f.preference.kept[Fixtures.householdId], ProductRetailer.pickNPay);
  });

  testWidgets(
    'a Pick n Pay run reads PnP’s shelves and search, never Checkers',
    (tester) async {
      await f.pump(tester);
      await f.tapKey(tester, 'plan-week-shop-pickNPay');
      await f.tapKey(tester, 'plan-week-ideas');
      expect(f.aisle.askedFor, [ProductRetailer.pickNPay]);
      expect(
        find.text(PlanWeekCopy.ideasHeadline(ProductRetailer.pickNPay)),
        findsOneWidget,
      );
      await f.tapKey(tester, 'plan-week-search');
      expect(f.pnp.queries, ['yoghurt']);
      expect(f.checkers.queries, isEmpty);
    },
  );

  testWidgets('the week goes onto the list matched at PnP, then into the cart '
      'with its packs', (tester) async {
    f.directory.pushResult = const CartPushResult(
      added: [
        CartAddedLine(
          itemId: 'item-1',
          productId: PlanWeekPnpFixture.yoghurtCode,
          name: 'PnP yoghurt 6 x 100g',
          price: Money(3499),
        ),
      ],
      skipped: [],
      cartItemCount: 3,
      cartTotal: Money(10497),
    );
    await f.pump(tester);
    await f.run(tester);
    expect(find.text(PnpCopy.addToMyCart), findsOneWidget);

    await f.tapThenList(tester, 'plan-week-cart');
    final match = f.harness.groceries.addedMatched.single.match;
    expect(match.retailer, ProductRetailer.pickNPay);
    expect(match.productId, PlanWeekPnpFixture.yoghurtCode);
    expect(match.articleCode, '000000000000539078');
    final pushed = f.directory.pushes.single;
    expect(pushed.itemIds, hasLength(1));
    expect(pushed.quantities.values.single, 1);
    expect(find.text(CartPushCopy.addedCount(1)), findsOneWidget);
    expect(
      find.text(CartPushCopy.finishIn(ProductRetailer.pickNPay)),
      findsOneWidget,
    );
  });

  testWidgets('no link yet: the sheet says link first', (tester) async {
    f.directory.pushFailures.add(const PnpFailure(PnpProblem.linkExpired));
    await f.pump(tester);
    await f.run(tester);
    await f.tapThenList(tester, 'plan-week-cart');
    expect(
      find.text(CartPushCopy.needsLink(ProductRetailer.pickNPay)),
      findsOneWidget,
    );
    expect(
      find.text(CartPushCopy.link(ProductRetailer.pickNPay)),
      findsOneWidget,
    );
  });

  testWidgets('PnP down is said in words, with a retry that works', (
    tester,
  ) async {
    f.directory.pushFailures.add(const PnpFailure(PnpProblem.pnpDown));
    await f.pump(tester);
    await f.run(tester);
    await f.tapThenList(tester, 'plan-week-cart');
    expect(
      find.text(AppCopy.failure(const PnpFailure(PnpProblem.pnpDown))),
      findsOneWidget,
    );
    await tester.tap(find.text(CartPushCopy.retry));
    await tester.pumpAndSettle();
    expect(f.directory.pushes, hasLength(2));
    expect(find.text(CartPushCopy.emptyTitle), findsOneWidget);
  });

  testWidgets('pushing shows its working', (tester) async {
    f.directory.pushGate = Completer<void>();
    await f.pump(tester);
    await f.run(tester);
    await f.tapThenList(tester, 'plan-week-cart', settle: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.text(CartPushCopy.pushing(ProductRetailer.pickNPay)),
      findsOneWidget,
    );
    f.directory.pushGate!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets(
    'the brief and the done step render dark at 200% on a small phone',
    (tester) async {
      await f.pump(
        tester,
        brightness: Brightness.dark,
        scale: 2,
        size: const Size(360, 800),
      );
      expect(tester.takeException(), isNull);
      await f.run(tester);
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(Scrollable).last, const Offset(0, -3000));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
