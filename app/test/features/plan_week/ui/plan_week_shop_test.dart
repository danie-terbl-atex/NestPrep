import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/add_to_checkers/model/cart_push_result.dart';
import 'package:nestprep/features/add_to_checkers/ui/retailer_logo.dart';
import 'package:nestprep/features/add_to_checkers/ui/shop_cart_links.dart';
import 'package:nestprep/features/groceries/model/product_match.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/cart_push_copy.dart';
import 'package:nestprep/shared/copy/checkers_copy.dart';
import 'package:nestprep/shared/copy/lunch_shop_copy.dart';
import 'package:nestprep/shared/money/money.dart';

import '../../../support/household_fixtures.dart';
import '../../../support/plan_week_shop_fixture.dart';

/// *Plan my week* at every shop alike (lunch-box ADR-0026, add-to-pnp
/// ADR-0004, ADR-0007): the brief offers the shops switched on, a run reads
/// only its shop's shelves and search, and the done step puts the week into
/// the member's own cart there — four states, in words.
void main() {
  testWidgets('with every shop on, the brief offers all three by their '
      'logos', (tester) async {
    final f = PlanWeekShopFixture();
    addTearDown(f.close);
    await f.pump(tester);
    expect(find.text(LunchShopCopy.chooseShop), findsOneWidget);
    for (final shop in ProductRetailer.values) {
      expect(
        find.byKey(ValueKey('plan-week-shop-${shop.code}')),
        findsOneWidget,
      );
    }
    expect(find.byType(RetailerLogo), findsNWidgets(3));
  });

  for (final shop in ProductRetailer.values) {
    group(CheckersCopy.retailerName(shop), () {
      late PlanWeekShopFixture f;

      setUp(() => f = PlanWeekShopFixture(shop: shop));
      tearDown(() => f.close());

      testWidgets('alone on, the brief names it and offers no choice', (
        tester,
      ) async {
        f.shopsOn = [shop];
        await f.pump(tester);
        expect(find.text(LunchShopCopy.chooseShop), findsNothing);
        expect(find.text(LunchShopCopy.shopOnly(shop)), findsOneWidget);
      });

      testWidgets('choosing it is remembered', (tester) async {
        await f.pump(tester);
        await f.choose(tester);
        expect(
          find.text(LunchShopCopy.shopNear(shop, 'Cape Town')),
          findsOneWidget,
        );
        expect(f.preference.kept[Fixtures.householdId], shop);
      });

      testWidgets('a run reads its shelves and search, never another shop’s', (
        tester,
      ) async {
        await f.pump(tester);
        await f.run(tester, last: 'plan-week-ideas');
        expect(f.aisle.askedFor, [shop]);
        expect(find.text(PlanWeekCopy.ideasHeadline(shop)), findsOneWidget);
        await f.tapKey(tester, 'plan-week-search');
        expect(f.catalogue.queries, ['yoghurt']);
        for (final other in ProductRetailer.values) {
          if (other != shop) expect(f.catalogues[other]!.queries, isEmpty);
        }
      });

      testWidgets('the week goes onto the list matched there, then into its '
          'cart', (tester) async {
        f.pusher.pushResult = CartPushResult(
          added: [
            CartAddedLine(
              itemId: 'item-1',
              productId: f.yoghurt.id,
              name: f.yoghurt.name,
              price: const Money(3499),
            ),
          ],
          skipped: const [],
          cartItemCount: 3,
          cartTotal: const Money(10497),
        );
        await f.pump(tester);
        await f.run(tester);
        expect(find.text(CartPushCopy.addToMyCart(shop)), findsOneWidget);

        await f.tapThenList(tester, 'plan-week-cart');
        final match = f.harness.groceries.addedMatched.single.match;
        expect(match.retailer, shop);
        expect(match.productId, f.yoghurt.id);
        final pushed = f.pusher.pushes.single;
        expect(pushed.itemIds, hasLength(1));
        expect(
          pushed.quantities.values,
          takesPackQuantities(shop) ? [1] : isEmpty,
        );
        for (final other in ProductRetailer.values) {
          if (other != shop) expect(f.pushers[other]!.pushes, isEmpty);
        }
        expect(find.text(CartPushCopy.addedCount(1)), findsOneWidget);
        expect(find.text(CartPushCopy.finishIn(shop)), findsOneWidget);
      });

      testWidgets('no link yet: the sheet says link first', (tester) async {
        f.pusher.pushFailures.add(linkExpiredAt(shop));
        await f.pump(tester);
        await f.run(tester);
        await f.tapThenList(tester, 'plan-week-cart');
        expect(find.text(CartPushCopy.needsLink(shop)), findsOneWidget);
        expect(find.text(CartPushCopy.link(shop)), findsOneWidget);
      });

      testWidgets('the shop down is said in words, with a retry that works', (
        tester,
      ) async {
        f.pusher.pushFailures.add(shopDownAt(shop));
        await f.pump(tester);
        await f.run(tester);
        await f.tapThenList(tester, 'plan-week-cart');
        expect(find.text(AppCopy.failure(shopDownAt(shop))), findsOneWidget);
        await tester.tap(find.text(CartPushCopy.retry));
        await tester.pumpAndSettle();
        expect(f.pusher.pushes, hasLength(2));
        expect(find.text(CartPushCopy.emptyTitle), findsOneWidget);
      });

      testWidgets('pushing shows its working', (tester) async {
        f.pusher.pushGate = Completer<void>();
        await f.pump(tester);
        await f.run(tester);
        await f.tapThenList(tester, 'plan-week-cart', settle: false);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text(CartPushCopy.pushing(shop)), findsOneWidget);
        f.pusher.pushGate!.complete();
        await tester.pumpAndSettle();
      });
    });
  }

  group('a product its shop says nothing of what is in', () {
    final caution = find.byKey(
      const ValueKey('plan-label-check-${PlanWeekShopFixture.lwazi}'),
    );

    testWidgets('at Woolworths, goes to the allergic child with a caution on '
        'the week', (tester) async {
      final f = PlanWeekShopFixture(
        shop: ProductRetailer.woolworths,
        isContentsKnown: false,
      );
      addTearDown(f.close);
      await f.pump(tester);
      await f.run(tester, last: 'plan-week-search');
      expect(caution, findsOneWidget);
      expect(
        find.text(
          PlanWeekCopy.labelCheckOf(ProductRetailer.woolworths, [
            f.yoghurt.name,
          ]),
        ),
        findsOneWidget,
      );
    });

    testWidgets('at Checkers, is still kept from the allergic child', (
      tester,
    ) async {
      final f = PlanWeekShopFixture(
        shop: ProductRetailer.checkers,
        isContentsKnown: false,
      );
      addTearDown(f.close);
      await f.pump(tester);
      await f.run(tester, last: 'plan-week-search');
      expect(caution, findsNothing);
      expect(
        find.byKey(const ValueKey('plan-week-nothing-kept')),
        findsOneWidget,
      );
    });

    testWidgets('the caution holds dark at 200% on a 360-wide phone', (
      tester,
    ) async {
      final f = PlanWeekShopFixture(
        shop: ProductRetailer.woolworths,
        isContentsKnown: false,
      );
      addTearDown(f.close);
      await f.pump(
        tester,
        brightness: Brightness.dark,
        scale: 2,
        size: const Size(360, 800),
      );
      await f.run(tester, last: 'plan-week-search');
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        caution,
        300,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(caution, findsOneWidget);
    });
  });

  testWidgets('the brief, with three shops to choose from, and the done step '
      'render dark at 200% on a small phone', (tester) async {
    final f = PlanWeekShopFixture(shop: ProductRetailer.woolworths);
    addTearDown(f.close);
    await f.pump(
      tester,
      brightness: Brightness.dark,
      scale: 2,
      size: const Size(360, 800),
    );
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('plan-week-shop-woolworths')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(RetailerLogo), findsNWidgets(3));
    await f.run(tester);
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      find.text(CartPushCopy.addToMyCart(ProductRetailer.woolworths)),
      findsOneWidget,
    );
  });
}
