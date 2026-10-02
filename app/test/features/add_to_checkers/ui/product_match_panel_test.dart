import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/groceries/model/product_match.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/checkers_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/bring_into_view.dart';
import '../../../support/checkers_grocery_harness.dart';
import '../../../support/grocery_list_harness.dart';

/// The product matches under a grocery item: its four states, picking, and
/// what a picked item then shows (`FE-08`, `FE-20`).
void main() {
  Future<CheckersGroceryHarness> openMatches(WidgetTester tester) async {
    final h = CheckersGroceryHarness();
    await h.pump(tester);
    h.list.repository.emitItems([groceryItem('milk')]);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byTooltip(CheckersCopy.findAt(ProductRetailer.checkers)),
    );
    return h;
  }

  testWidgets('holds its place while Checkers answers', (tester) async {
    final h = CheckersGroceryHarness()..catalogue.gate = Completer<void>();
    await h.pump(tester);
    h.list.repository.emitItems([groceryItem('milk')]);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byTooltip(CheckersCopy.findAt(ProductRetailer.checkers)),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text(CheckersCopy.matchesTitle('milk')), findsOneWidget);
    expect(find.byType(NestSkeleton), findsWidgets);
    h.catalogue.gate!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('shows the matches with price, deal and stock in words', (
    tester,
  ) async {
    await openMatches(tester);
    await tester.pumpAndSettle();

    expect(find.text('Clover Fresh Full Cream Milk 2L'), findsOneWidget);
    expect(find.text('R37.99'), findsOneWidget);
    expect(find.text('was R42.99'), findsOneWidget);
    expect(find.text('Darling Fresh Full Cream Milk 2L'), findsOneWidget);
    expect(find.text(CheckersCopy.deal), findsOneWidget);
    expect(find.text(CheckersCopy.outOfStock), findsOneWidget);
    expect(find.text(CheckersCopy.nearArea('Cape Town')), findsOneWidget);
  });

  testWidgets('says when nothing is close, and the item stays on the list', (
    tester,
  ) async {
    final h = CheckersGroceryHarness()..catalogue.products = const [];
    await h.pump(tester);
    h.list.repository.emitItems([groceryItem('unobtainium')]);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byTooltip(CheckersCopy.findAt(ProductRetailer.checkers)),
    );
    await tester.pumpAndSettle();

    expect(find.text(CheckersCopy.matchesEmptyTitle), findsOneWidget);
    expect(find.text('unobtainium'), findsOneWidget);
  });

  testWidgets('a failure is human copy with a retry that works', (
    tester,
  ) async {
    final h = CheckersGroceryHarness()
      ..catalogue.failWith = const CheckersFailure(
        CheckersProblem.catalogueBusy,
      );
    await h.pump(tester);
    h.list.repository.emitItems([groceryItem('milk')]);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byTooltip(CheckersCopy.findAt(ProductRetailer.checkers)),
    );
    await tester.pumpAndSettle();

    const failure = CheckersFailure(CheckersProblem.catalogueBusy);
    expect(find.text(AppCopy.failure(failure)), findsOneWidget);
    h.catalogue.failWith = null;
    await bringIntoView(tester, find.text(CheckersCopy.retry));
    await tester.tap(find.text(CheckersCopy.retry));
    await tester.pumpAndSettle();
    expect(find.text('Clover Fresh Full Cream Milk 2L'), findsOneWidget);
  });

  testWidgets('the find button steps aside while its panel is open', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = CheckersGroceryHarness();
    await h.pump(tester);
    h.list.repository.emitItems([
      groceryItem('milk'),
      groceryItem('bread', id: 'b'),
    ]);
    await tester.pumpAndSettle();
    expect(
      find.byTooltip(CheckersCopy.findAt(ProductRetailer.checkers)),
      findsNWidgets(2),
    );

    await tester.tap(
      find.byTooltip(CheckersCopy.findAt(ProductRetailer.checkers)).first,
    );
    await tester.pumpAndSettle();
    expect(find.text(CheckersCopy.matchesTitle('milk')), findsOneWidget);
    expect(
      find.byTooltip(CheckersCopy.findAt(ProductRetailer.checkers)),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip(CheckersCopy.closeMatches));
    await tester.pumpAndSettle();
    expect(
      find.byTooltip(CheckersCopy.findAt(ProductRetailer.checkers)),
      findsNWidgets(2),
    );
  });

  testWidgets('picking stores the product and closes the panel', (
    tester,
  ) async {
    final h = await openMatches(tester);
    await tester.pumpAndSettle();
    await bringIntoView(tester, find.text(CheckersCopy.pick).first);
    await tester.tap(find.text(CheckersCopy.pick).first);
    await tester.pumpAndSettle();

    expect(
      h.list.repository.matchesSet.single.match.name,
      'Clover Fresh Full Cream Milk 2L',
    );
    expect(find.text(CheckersCopy.matchesTitle('milk')), findsNothing);
  });

  testWidgets('a matched item shows its product, and can change or clear it', (
    tester,
  ) async {
    final h = CheckersGroceryHarness();
    await h.pump(tester);
    h.list.repository.emitItems([
      groceryItem('milk').copyWith(productMatch: pickedMilk),
    ]);
    await tester.pumpAndSettle();

    expect(
      find.text('Clover Fresh Full Cream Milk 2L · R37.99'),
      findsOneWidget,
    );
    expect(
      find.byTooltip(CheckersCopy.findAt(ProductRetailer.checkers)),
      findsNothing,
    );

    await bringIntoView(tester, find.byTooltip(CheckersCopy.clearMatch));

    await tester.tap(find.byTooltip(CheckersCopy.clearMatch));
    await tester.pumpAndSettle();
    expect(h.list.repository.matchesCleared, ['i']);

    await bringIntoView(tester, find.byTooltip(CheckersCopy.changeMatch));

    await tester.tap(find.byTooltip(CheckersCopy.changeMatch));
    await tester.pumpAndSettle();
    expect(find.text(CheckersCopy.matchesTitle('milk')), findsOneWidget);
  });

  testWidgets('adding an item looks for its matches after it is saved', (
    tester,
  ) async {
    final h = CheckersGroceryHarness();
    await h.pump(tester);
    h.list.repository.emitItems(const []);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'eggs');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(h.list.repository.added.single.name, 'eggs');
    expect(h.catalogue.searches.single.query, 'eggs');
    expect(h.matches.target?.itemId, 'added-1');
  });

  testWidgets('with the switch off there is no Checkers at all', (
    tester,
  ) async {
    final h = CheckersGroceryHarness();
    await h.pump(tester, isOn: false);
    h.list.repository.emitItems([
      groceryItem('milk'),
      groceryItem('bread', id: 'b').copyWith(productMatch: pickedMilk),
    ]);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'eggs');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(
      find.byTooltip(CheckersCopy.findAt(ProductRetailer.checkers)),
      findsNothing,
    );
    expect(find.text(CheckersCopy.addToCheckers), findsNothing);
    expect(h.catalogue.searches, isEmpty);
  });

  testWidgets('the open panel survives dark at 200% text on a 360-wide phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final h = CheckersGroceryHarness();
    await h.pump(tester, brightness: Brightness.dark, scale: 2);
    h.list.repository.emitItems([
      groceryItem('milk'),
      groceryItem('bread', id: 'b').copyWith(productMatch: pickedMilk),
    ]);
    await tester.pumpAndSettle();
    // At 200% text the list is taller than the phone: scroll, as a person
    // would, to the item and then to its matches.
    final list = find
        .descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        )
        .first;
    final findAt = find.byTooltip(
      CheckersCopy.findAt(ProductRetailer.checkers),
    );
    await tester.scrollUntilVisible(findAt, 200, scrollable: list);
    await bringIntoView(tester, findAt);
    await tester.tap(findAt);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Clover Fresh Full Cream Milk 2L').first,
      200,
      scrollable: list,
    );

    expect(find.text('Clover Fresh Full Cream Milk 2L'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
