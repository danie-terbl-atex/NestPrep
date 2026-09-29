import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/grocery_list_harness.dart';

void main() {
  testWidgets('holds the layout while it loads rather than collapsing', (
    tester,
  ) async {
    await GroceryListHarness().pump(tester);
    await tester.pump();
    expect(find.text(AppCopy.groceriesTitle), findsOneWidget);
    expect(find.text(AppCopy.groceriesEmptyTitle), findsNothing);
  });

  testWidgets('says what to do next when the list is empty', (tester) async {
    final h = GroceryListHarness();
    await h.pump(tester);
    h.repository.emitItems(const []);
    await tester.pumpAndSettle();

    expect(find.text(AppCopy.groceriesEmptyTitle), findsOneWidget);
    expect(find.text(AppCopy.groceriesEmptyBody), findsOneWidget);
  });

  testWidgets('shows human copy and a way back when the read fails', (
    tester,
  ) async {
    final h = GroceryListHarness();
    await h.pump(tester);
    h.repository.failItemsWith(const UnavailableFailure());
    await tester.pumpAndSettle();

    expect(
      find.text(AppCopy.failure(const UnavailableFailure())),
      findsOneWidget,
    );
    expect(find.text(AppCopy.retry), findsOneWidget);
  });

  testWidgets('lists what is to buy and what was just bought', (tester) async {
    final h = GroceryListHarness();
    await h.pump(tester);
    h.repository.emitItems([
      groceryItem('Milk', id: 'milk'),
      groceryItem(
        'Bread',
        id: 'bread',
        boughtAt: groceryNow.subtract(const Duration(hours: 1)),
      ),
    ]);
    await tester.pumpAndSettle();

    expect(find.text(AppCopy.groceriesToBuy), findsOneWidget);
    expect(find.text(AppCopy.groceriesBought), findsOneWidget);
    expect(find.text('Milk'), findsOneWidget);
    // Bread is on the list struck through, and in the chips as something the
    // household buys — both are right, so name the one that matters.
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.data == 'Bread' &&
            widget.style?.decoration == TextDecoration.lineThrough,
      ),
      findsOneWidget,
    );
  });

  testWidgets('tapping a row ticks it off', (tester) async {
    final h = GroceryListHarness();
    await h.pump(tester);
    h.repository.emitItems([groceryItem('Milk', id: 'milk')]);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Milk'));
    await tester.pumpAndSettle();

    expect(h.repository.ticked.single.itemId, 'milk');
    expect(h.repository.ticked.single.isBought, isTrue);
  });

  testWidgets('a chip adds the item again in one tap', (tester) async {
    final h = GroceryListHarness();
    await h.pump(tester);
    h.repository.emitItems([
      groceryItem(
        'Milk',
        id: 'a',
        boughtAt: groceryNow.subtract(const Duration(days: 3)),
      ),
    ]);
    await tester.pumpAndSettle();

    expect(find.text(AppCopy.groceriesOften), findsOneWidget);
    expect(find.text(AppCopy.groceriesEmptyTitle), findsOneWidget);
    await tester.tap(find.text('Milk'));
    await tester.pumpAndSettle();

    expect(h.repository.added.single.name, 'Milk');
  });

  testWidgets('typing a name and submitting adds it and clears the field', (
    tester,
  ) async {
    final h = GroceryListHarness();
    await h.pump(tester);
    h.repository.emitItems(const []);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Eggs');
    await tester.pumpAndSettle();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(h.repository.added.single.name, 'Eggs');
    expect(find.text('Eggs'), findsNothing);
  });

  testWidgets('a refused write shows copy, never an error code', (
    tester,
  ) async {
    final h = GroceryListHarness();
    await h.pump(tester);
    h.repository.emitItems([groceryItem('Milk', id: 'milk')]);
    await tester.pumpAndSettle();

    h.repository.failWritesWith = const PermissionDeniedFailure();
    await tester.tap(find.text('Milk'));
    await tester.pumpAndSettle();

    expect(
      find.text(AppCopy.failure(const PermissionDeniedFailure())),
      findsOneWidget,
    );
    expect(find.textContaining('permission-denied'), findsNothing);
  });

  testWidgets('renders in dark and at 200% text without overflowing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final h = GroceryListHarness();
    await h.pump(tester, brightness: Brightness.dark, scale: 2);
    h.repository.emitItems([groceryItem('Full cream milk', id: 'milk')]);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Full cream milk'), findsOneWidget);
  });
}
