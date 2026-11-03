import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/basket_compare/model/basket_comparison.dart';
import 'package:nestprep/features/basket_compare/ui/basket_compare_body.dart';
import 'package:nestprep/features/basket_compare/ui/shop_total_card.dart';
import 'package:nestprep/features/groceries/model/product_match.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/basket_compare_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/money/money.dart';

import '../../../support/basket_compare_fixture.dart';

/// *Compare shops* as it renders a comparison (basket-compare ADR-0001): the
/// like-for-like verdict first, each shop's basket, the items some shop lacks
/// before the rest, and one shop for the whole list.
void main() {
  BasketComparison complete() {
    final mixed = mixedComparison();
    return BasketComparison(
      shops: mixed.shops,
      items: mixed.items.where((item) => item.lines.length == 2).toList(),
    );
  }

  Future<void> pump(
    WidgetTester tester,
    AsyncState<BasketComparison> state, {
    VoidCallback? onRetry,
    String? area,
    UseShopActions? useShop,
    Brightness brightness = Brightness.light,
    double scale = 1,
  }) async {
    await pumpCompareBody(
      tester,
      BasketCompareBody(
        comparison: state,
        onRetry: onRetry ?? () {},
        area: area,
        useShop: useShop,
      ),
      brightness: brightness,
      scale: scale,
    );
    await settleWithSkeletons(tester);
  }

  Future<void> scrollTo(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(
      target,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
  }

  testWidgets('names the cheapest shop like for like, with the saving', (
    tester,
  ) async {
    await pump(tester, AsyncData(mixedComparison()));
    expect(find.text(BasketCompareCopy.cheapest(pnp)), findsOneWidget);
    expect(
      find.text(BasketCompareCopy.saving(const Money(100), 2, 2)),
      findsOneWidget,
    );
    expect(find.text(BasketCompareCopy.soFar), findsOneWidget);
    expect(find.text(BasketCompareCopy.checking(5, 6)), findsOneWidget);
  });

  testWidgets('each shop shows its total, what it has and what it lacks', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(420, 4000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pump(tester, AsyncData(mixedComparison()));
    final checkersTotal = find.byKey(const ValueKey('total-checkers'));
    final pnpTotal = find.byKey(const ValueKey('total-pickNPay'));
    Finder within(Finder card, String text) =>
        find.descendant(of: card, matching: find.text(text));

    expect(within(checkersTotal, const Money(12196).display), findsOneWidget);
    expect(
      within(checkersTotal, BasketCompareCopy.foundOf(3, 5)),
      findsOneWidget,
    );
    expect(
      within(checkersTotal, BasketCompareCopy.notAvailable(2)),
      findsOneWidget,
    );
    expect(within(checkersTotal, BasketCompareCopy.cheapestTag), findsNothing);
    expect(
      within(
        checkersTotal,
        BasketCompareCopy.likeForLike(const Money(7597), 2),
      ),
      findsOneWidget,
    );

    expect(within(pnpTotal, const Money(17395).display), findsOneWidget);
    expect(within(pnpTotal, BasketCompareCopy.foundOf(4, 5)), findsOneWidget);
    expect(within(pnpTotal, BasketCompareCopy.notAvailable(1)), findsOneWidget);
    expect(within(pnpTotal, BasketCompareCopy.cheapestTag), findsOneWidget);
  });

  testWidgets('a split worth a rand or more is shown, as a figure only', (
    tester,
  ) async {
    await pump(tester, AsyncData(mixedComparison()));
    final split = find.text(
      BasketCompareCopy.split(const Money(7297), const Money(200)),
    );
    await scrollTo(tester, split);
    expect(split, findsOneWidget);
  });

  testWidgets('a split under a rand is not', (tester) async {
    await pump(
      tester,
      AsyncData(
        BasketComparison(
          shops: bothShops,
          items: [
            compared('Milk', [
              offer(checkers, 'Milk A', 3750),
              offer(pnp, 'Milk B', 3699),
            ]),
          ],
        ),
      ),
    );
    expect(find.byType(SplitHint), findsNothing);
  });

  testWidgets('what a shop lacks comes before what every shop has', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(420, 4000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pump(tester, AsyncData(mixedComparison()));
    final lacking = find.text(BasketCompareCopy.notEverywhereTitle(2));
    final everywhere = find.text(BasketCompareCopy.everywhereTitle(2));
    final pending = find.text(BasketCompareCopy.stillChecking);
    expect(
      tester.getTopLeft(lacking).dy,
      lessThan(tester.getTopLeft(everywhere).dy),
    );
    expect(
      tester.getTopLeft(everywhere).dy,
      lessThan(tester.getTopLeft(pending).dy),
    );
    expect(find.text(BasketCompareCopy.notAt(pnp)), findsOneWidget);
    expect(find.text(BasketCompareCopy.outOfStockAt(checkers)), findsOneWidget);
    expect(find.text(BasketCompareCopy.unreachable(checkers)), findsOneWidget);
  });

  testWidgets('each line shows its price, the cheapest marked in words', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(420, 4000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pump(tester, AsyncData(mixedComparison()));
    final milk = find.byKey(const ValueKey('item-id-Milk'));
    final bread = find.byKey(const ValueKey('item-id-Bread'));
    Finder within(Finder card, String text) =>
        find.descendant(of: card, matching: find.text(text));

    expect(within(milk, const Money(3499).display), findsOneWidget);
    expect(
      within(milk, BasketCompareCopy.was(const Money(3999))),
      findsOneWidget,
    );
    expect(within(milk, BasketCompareCopy.deal), findsOneWidget);
    expect(within(milk, BasketCompareCopy.cheapestTag), findsOneWidget);

    expect(within(bread, BasketCompareCopy.packs(2)), findsOneWidget);
    expect(within(bread, const Money(3798).display), findsOneWidget);
    expect(
      within(bread, BasketCompareCopy.perPack(const Money(1999), 2)),
      findsOneWidget,
    );
    expect(within(bread, BasketCompareCopy.pickedEarlier), findsOneWidget);
    expect(find.text(BasketCompareCopy.closest), findsOneWidget);
  });

  testWidgets('a shop that could not be reached offers to try again', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(420, 4000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var retried = 0;
    await pump(tester, AsyncData(mixedComparison()), onRetry: () => retried++);
    await tester.tap(find.byKey(const ValueKey('retry-checkers')));
    expect(retried, 1);
  });

  testWidgets('the same price at both shops says so', (tester) async {
    await pump(
      tester,
      AsyncData(
        BasketComparison(
          shops: bothShops,
          items: [
            compared('Milk', [
              offer(checkers, 'Milk A', 3499),
              offer(pnp, 'Milk B', 3499),
            ]),
          ],
        ),
      ),
    );
    expect(find.text(BasketCompareCopy.samePrice(2)), findsOneWidget);
    expect(
      find.text(BasketCompareCopy.samePriceBody(const Money(3499), 1, 2)),
      findsOneWidget,
    );
  });

  testWidgets('nothing at both shops explains there is no fair verdict', (
    tester,
  ) async {
    await pump(
      tester,
      AsyncData(
        BasketComparison(
          shops: bothShops,
          items: [
            compared('Milk', [
              offer(checkers, 'Milk A', 3499),
              const ShopMiss(shop: pnp, reason: ShopMissReason.notFound),
            ]),
          ],
        ),
      ),
    );
    expect(find.text(BasketCompareCopy.noCommonTitle), findsOneWidget);
    expect(find.text(BasketCompareCopy.noCommonBody(2)), findsOneWidget);
  });

  testWidgets('before any shop answers, it says the verdict is coming', (
    tester,
  ) async {
    await pump(
      tester,
      AsyncData(
        BasketComparison(shops: bothShops, items: [compared('Milk', const [])]),
      ),
    );
    expect(find.text(BasketCompareCopy.waitingTitle), findsOneWidget);
    expect(find.text(BasketCompareCopy.checking(0, 1)), findsOneWidget);
  });

  testWidgets('three shops are "every shop", not "both"', (tester) async {
    const shops = [checkers, pnp, ProductRetailer.woolworths];
    await pump(
      tester,
      AsyncData(
        BasketComparison(
          shops: shops,
          items: [
            compared('Milk', [
              offer(checkers, 'Milk A', 3799),
              offer(pnp, 'Milk B', 3499),
              offer(ProductRetailer.woolworths, 'Milk C', 4299),
            ]),
          ],
        ),
      ),
    );
    expect(
      find.text(BasketCompareCopy.saving(const Money(800), 1, 3)),
      findsOneWidget,
    );
    expect(find.textContaining('every shop has'), findsOneWidget);
  });

  testWidgets('an empty list says there is nothing to compare', (tester) async {
    await pump(
      tester,
      const AsyncData(BasketComparison(shops: bothShops, items: [])),
    );
    await tester.pumpAndSettle();
    expect(find.text(BasketCompareCopy.emptyTitle), findsOneWidget);
  });

  testWidgets('a failed read shows copy and tries again', (tester) async {
    var retried = 0;
    await pump(
      tester,
      const AsyncFailure(UnavailableFailure()),
      onRetry: () => retried++,
    );
    await tester.pumpAndSettle();
    expect(
      find.text(AppCopy.failure(const UnavailableFailure())),
      findsOneWidget,
    );
    await tester.tap(find.text(AppCopy.retry));
    expect(retried, 1);
  });

  testWidgets('the footer names where the prices are from', (tester) async {
    await pump(tester, AsyncData(complete()), area: 'Cape Town');
    final footer = find.text(BasketCompareCopy.footer('Cape Town'));
    await scrollTo(tester, footer);
    expect(footer, findsOneWidget);
  });

  group('one shop for the list', () {
    UseShopActions actions(
      List<ProductRetailer> used, {
      bool isApplying = false,
      Set<ProductRetailer> withMatches = const {checkers, pnp},
    }) => UseShopActions(
      isApplying: isApplying,
      hasMatchesAt: withMatches.contains,
      onUse: used.add,
    );

    Finder button(ProductRetailer shop) =>
        find.byKey(ValueKey('use-${shop.code}'));

    NestButton buttonOf(WidgetTester tester, ProductRetailer shop) =>
        tester.widget<NestButton>(button(shop));

    testWidgets('is not offered to somebody who may only read', (tester) async {
      await pump(tester, AsyncData(complete()));
      expect(find.text(BasketCompareCopy.useTitle), findsNothing);
      expect(button(pnp), findsNothing);
    });

    testWidgets('offers each shop, the cheapest first, and reports a tap', (
      tester,
    ) async {
      final used = <ProductRetailer>[];
      await pump(tester, AsyncData(complete()), useShop: actions(used));
      await scrollTo(tester, button(checkers));
      expect(
        tester.getTopLeft(button(pnp)).dy,
        lessThan(tester.getTopLeft(button(checkers)).dy),
      );
      expect(find.text(BasketCompareCopy.useShop(pnp)), findsOneWidget);
      await tester.tap(button(pnp));
      expect(used, [pnp]);
    });

    testWidgets('waits for every shop to answer', (tester) async {
      await pump(tester, AsyncData(mixedComparison()), useShop: actions([]));
      await scrollTo(tester, button(checkers));
      expect(buttonOf(tester, pnp).onPressed, isNull);
      expect(buttonOf(tester, checkers).onPressed, isNull);
    });

    testWidgets('a shop with nothing to pick cannot be used', (tester) async {
      await pump(
        tester,
        AsyncData(complete()),
        useShop: actions([], withMatches: {pnp}),
      );
      await scrollTo(tester, button(checkers));
      expect(buttonOf(tester, pnp).onPressed, isNotNull);
      expect(buttonOf(tester, checkers).onPressed, isNull);
    });

    testWidgets('nothing is tapped twice while it applies', (tester) async {
      await pump(
        tester,
        AsyncData(complete()),
        useShop: actions([], isApplying: true),
      );
      await scrollTo(tester, button(checkers));
      expect(buttonOf(tester, pnp).onPressed, isNull);
      expect(buttonOf(tester, checkers).onPressed, isNull);
    });
  });

  for (final brightness in [Brightness.light, Brightness.dark]) {
    testWidgets('a mixed comparison fits a 360-wide phone at 200% text '
        '(${brightness.name})', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 780));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await pump(
        tester,
        AsyncData(mixedComparison()),
        area: 'Cape Town',
        useShop: anyShop(),
        brightness: brightness,
        scale: 2,
      );
      expect(tester.takeException(), isNull);
      for (var page = 0; page < 30; page++) {
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -400));
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
      }
      expect(find.text(BasketCompareCopy.footer('Cape Town')), findsOneWidget);
    });
  }
}

UseShopActions anyShop() =>
    UseShopActions(isApplying: false, hasMatchesAt: (_) => true, onUse: (_) {});
