import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/add_to_checkers/model/cart_push_result.dart';
import 'package:nestprep/features/groceries/model/product_match.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/cart_push_copy.dart';
import 'package:nestprep/shared/copy/checkers_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/money/money.dart';

import '../../../support/bring_into_view.dart';
import '../../../support/checkers_grocery_harness.dart';
import '../../../support/grocery_list_harness.dart';

/// *Add to Checkers* from the list: the bar, the sheet's four states, and
/// linking again when the hour has run out (`FE-08`, `FE-20`).
void main() {
  Future<CheckersGroceryHarness> listWithMatches(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    double scale = 1,
  }) async {
    final h = CheckersGroceryHarness();
    await h.pump(tester, brightness: brightness, scale: scale);
    h.list.repository.emitItems([
      groceryItem('milk', id: 'm').copyWith(productMatch: pickedMilk),
      groceryItem('chicken', id: 'c').copyWith(productMatch: pickedMilk),
      groceryItem('salt', id: 's'),
    ]);
    await tester.pumpAndSettle();
    return h;
  }

  testWidgets('only matched items are offered, and only they are sent', (
    tester,
  ) async {
    final h = await listWithMatches(tester);
    expect(
      find.text(CheckersCopy.readyToAdd(ProductRetailer.checkers, 2)),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('add-to-cart-checkers')));
    await tester.pumpAndSettle();
    expect(h.directory.pushes.single.itemIds, ['m', 'c']);
  });

  testWidgets('says it is adding while the cart is being filled', (
    tester,
  ) async {
    final h = await listWithMatches(tester);
    h.directory.pushGate = Completer<void>();
    await tester.tap(find.byKey(const ValueKey('add-to-cart-checkers')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.text(CartPushCopy.pushing(ProductRetailer.checkers)),
      findsOneWidget,
    );
    h.directory.pushGate!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('what was added, what was not and why, and the cart', (
    tester,
  ) async {
    final h = await listWithMatches(tester);
    h.directory.pushResult = const CartPushResult(
      added: [
        CartAddedLine(
          itemId: 'm',
          productId: '5d3af63bf434cf8420737dd6',
          name: 'Clover Fresh Full Cream Milk 2L',
          price: Money(3799),
        ),
      ],
      skipped: [
        CartSkippedLine(itemId: 'c', reason: CartSkipReason.weighedItem),
      ],
      cartItemCount: 5,
      cartTotal: Money(21450),
    );
    await tester.tap(find.byKey(const ValueKey('add-to-cart-checkers')));
    await tester.pumpAndSettle();

    expect(find.text(CartPushCopy.addedCount(1)), findsOneWidget);
    expect(find.text('Clover Fresh Full Cream Milk 2L'), findsWidgets);
    expect(find.text(CartPushCopy.skippedCount(1)), findsOneWidget);
    expect(
      find.text(CartPushCopy.skipWeighed(ProductRetailer.checkers)),
      findsOneWidget,
    );
    expect(
      find.text(CartPushCopy.cartSummary(5, const Money(21450))),
      findsOneWidget,
    );
    expect(
      find.text(CartPushCopy.finishIn(ProductRetailer.checkers)),
      findsOneWidget,
    );
  });

  testWidgets('nothing added says so, with each reason', (tester) async {
    final h = await listWithMatches(tester);
    h.directory.pushResult = const CartPushResult(
      added: [],
      skipped: [
        CartSkippedLine(itemId: 'm', reason: CartSkipReason.outOfStock),
      ],
      cartItemCount: 0,
      cartTotal: Money.zero(),
    );
    await tester.tap(find.byKey(const ValueKey('add-to-cart-checkers')));
    await tester.pumpAndSettle();

    expect(find.text(CartPushCopy.emptyTitle), findsOneWidget);
    expect(find.text(CartPushCopy.skipOutOfStock), findsOneWidget);
    expect(find.text('milk'), findsWidgets);
  });

  testWidgets('a failure is human copy with a retry that works', (
    tester,
  ) async {
    final h = await listWithMatches(tester);
    const failure = CheckersFailure(CheckersProblem.checkersDown);
    h.directory.pushFailures.add(failure);
    await tester.tap(find.byKey(const ValueKey('add-to-cart-checkers')));
    await tester.pumpAndSettle();

    expect(find.text(AppCopy.failure(failure)), findsOneWidget);
    await tester.tap(find.widgetWithText(NestButton, CheckersCopy.retry));
    await tester.pumpAndSettle();
    expect(h.directory.pushes, hasLength(2));
    expect(
      find.text(CartPushCopy.finishIn(ProductRetailer.checkers)),
      findsOneWidget,
    );
  });

  testWidgets('a link that ran out sends them to link, then pushes again', (
    tester,
  ) async {
    final h = await listWithMatches(tester);
    h.directory.pushFailures.add(
      const CheckersFailure(CheckersProblem.linkExpired),
    );
    await tester.tap(find.byKey(const ValueKey('add-to-cart-checkers')));
    await tester.pumpAndSettle();
    expect(
      find.text(CheckersCopy.problem(CheckersProblem.linkExpired)),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(NestButton, CheckersCopy.linkTitle));
    await tester.pumpAndSettle();
    expect(find.text(CheckersCopy.notAffiliated), findsOneWidget);

    await tester.enterText(find.byType(TextField), '082 123 4567');
    await tester.pump();
    await tester.tap(find.text(CheckersCopy.sendCode));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    await tester.tap(find.text(CheckersCopy.verify));
    await tester.pumpAndSettle();

    expect(h.directory.pushes, hasLength(2));
    expect(h.directory.pushes.last.itemIds, ['m', 'c']);
    expect(
      find.text(CartPushCopy.finishIn(ProductRetailer.checkers)),
      findsOneWidget,
    );
  });

  testWidgets('the result survives dark at 200% text on a 360-wide phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final h = await listWithMatches(
      tester,
      brightness: Brightness.dark,
      scale: 2,
    );
    h.directory.pushResult = const CartPushResult(
      added: [
        CartAddedLine(
          itemId: 'm',
          productId: 'p',
          name: 'Clover Fresh Full Cream Milk 2L',
          price: Money(3799),
        ),
      ],
      skipped: [CartSkippedLine(itemId: 'c', reason: CartSkipReason.notFound)],
      cartItemCount: 12,
      cartTotal: Money(123456),
    );
    await bringIntoView(
      tester,
      find.byKey(const ValueKey('add-to-cart-checkers')),
    );
    await tester.tap(find.byKey(const ValueKey('add-to-cart-checkers')));
    await tester.pumpAndSettle();
    expect(
      find.text(CartPushCopy.finishIn(ProductRetailer.checkers)),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
