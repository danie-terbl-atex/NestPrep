import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/add_to_checkers/ui/list_match_dock.dart';
import 'package:nestprep/features/add_to_checkers/ui/list_match_page.dart';
import 'package:nestprep/features/add_to_checkers/ui/list_match_summary.dart';
import 'package:nestprep/features/groceries/model/product_match.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/checkers_copy.dart';
import 'package:nestprep/shared/copy/list_match_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/checkers_grocery_harness.dart';
import '../../../support/fake_checkers.dart';
import '../../../support/grocery_list_harness.dart';

/// *Find at* for the unmatched items (groceries ADR-0010): one item per
/// step, the shop's products to pick from, and *Skip*, *Remove* and *Next*.
void main() {
  Future<CheckersGroceryHarness> open(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    double scale = 1,
    Map<String, double> fits = const {},
    void Function(CheckersGroceryHarness h)? before,
  }) async {
    final h = CheckersGroceryHarness();
    h.catalogue.products = [
      checkersProduct('Clover Fresh Full Cream Milk 2L', id: 'a'),
      checkersProduct(
        'Darling Fresh Full Cream Milk 2L',
        id: 'b',
        cents: 3299,
        isOnPromotion: true,
      ),
      checkersProduct('Parmalat Milk 1L', id: 'c', isInStock: false),
    ];
    h.ranker.fits = fits;
    before?.call(h);
    await h.pump(tester, brightness: brightness, scale: scale);
    h.list.repository.emitItems([
      groceryItem('milk', id: 'm'),
      groceryItem('salt', id: 's'),
      groceryItem('pepper', id: 'p'),
    ]);
    await tester.pumpAndSettle();
    final find_ = find.byKey(const ValueKey('find-unmatched'));
    await tester.ensureVisible(find_);
    await tester.pumpAndSettle();
    await tester.tap(find_);
    await tester.pumpAndSettle();
    return h;
  }

  Future<void> tap(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  Finder product(String id) => find.byKey(ValueKey('list-match-$id'));

  double dockHeight(WidgetTester tester) =>
      tester.getSize(find.byType(NestDock)).height;

  testWidgets('opens on the first item, with Next away until a product is '
      'selected', (tester) async {
    await open(tester);
    expect(find.text('milk'), findsOneWidget);
    expect(find.text(ListMatchCopy.step(0, 3)), findsOneWidget);
    expect(find.text(ListMatchCopy.picked(0)), findsOneWidget);
    expect(find.byKey(ListMatchDock.nextKey), findsNothing);
    expect(find.text(ListMatchCopy.chooseHint), findsOneWidget);
    expect(find.byKey(ListMatchDock.skipKey), findsOneWidget);
    expect(find.byKey(ListMatchDock.removeKey), findsOneWidget);

    final before = dockHeight(tester);
    await tap(tester, product('a'));
    expect(find.byKey(ListMatchDock.nextKey), findsOneWidget);
    expect(dockHeight(tester), before);

    await tap(tester, product('a'));
    expect(find.byKey(ListMatchDock.nextKey), findsNothing);
  });

  testWidgets('Jev\'s best match is selected already and says so', (
    tester,
  ) async {
    await open(tester, fits: {'b': 0.9});
    expect(find.byKey(ListMatchDock.nextKey), findsOneWidget);
    expect(find.text(CheckersCopy.bestMatch), findsOneWidget);
    expect(
      tester
          .widget<NestPickTile>(
            find.descendant(
              of: product('b'),
              matching: find.byType(NestPickTile),
            ),
          )
          .isSelected,
      isTrue,
    );
  });

  testWidgets('Next saves the pick and shows the next item', (tester) async {
    final h = await open(tester);
    await tap(tester, product('b'));
    await tap(tester, find.byKey(ListMatchDock.nextKey));
    expect(h.list.repository.matchesSet.single.itemId, 'm');
    expect(h.list.repository.matchesSet.single.match.productId, 'b');
    expect(find.text('salt'), findsOneWidget);
    expect(find.text(ListMatchCopy.step(1, 3)), findsOneWidget);
    expect(find.text(ListMatchCopy.picked(1)), findsOneWidget);
  });

  testWidgets('a pick, a skip and a removal end on the summary; the removal '
      'happens when the page closes', (tester) async {
    final h = await open(tester);
    await tap(tester, product('a'));
    await tap(tester, find.byKey(ListMatchDock.nextKey));
    await tap(tester, find.byKey(ListMatchDock.skipKey));
    await tap(tester, find.byKey(ListMatchDock.removeKey));

    expect(find.byType(ListMatchSummary), findsOneWidget);
    expect(find.text(ListMatchCopy.summaryFigure(1, 3)), findsOneWidget);
    expect(
      find.text(ListMatchCopy.summaryMatched(ProductRetailer.checkers)),
      findsOneWidget,
    );
    expect(find.text(ListMatchCopy.skipped(1)), findsOneWidget);
    expect(find.text(ListMatchCopy.removed(1)), findsOneWidget);
    expect(h.list.repository.removed, isEmpty);
    expect(dockHeight(tester), lessThan(300));

    await tap(tester, find.byKey(ListMatchSummaryActions.doneKey));
    expect(find.byType(ListMatchPage), findsNothing);
    expect(h.list.repository.removed, ['p']);
    expect(h.directory.pushes, isEmpty);
  });

  testWidgets('a removed item can be kept by stepping back', (tester) async {
    final h = await open(tester);
    await tap(tester, find.byKey(ListMatchDock.removeKey));
    await tap(tester, find.byTooltip(ListMatchCopy.previous));
    expect(find.text(ListMatchCopy.removedBody('milk')), findsOneWidget);
    await tap(tester, find.text(ListMatchCopy.keep));
    expect(find.text(ListMatchCopy.removedBody('milk')), findsNothing);
    expect(product('a'), findsOneWidget);

    await tap(tester, find.byTooltip(ListMatchCopy.close));
    expect(h.list.repository.removed, isEmpty);
  });

  testWidgets('Add to my cart closes the page and sends what is matched at '
      'the shop', (tester) async {
    final h = await open(tester);
    await tap(tester, product('a'));
    await tap(tester, find.byKey(ListMatchDock.nextKey));
    h.list.repository.emitItems([
      groceryItem('milk', id: 'm').copyWith(productMatch: pickedMilk),
      groceryItem('salt', id: 's'),
      groceryItem('pepper', id: 'p'),
    ]);
    await tap(tester, find.byKey(ListMatchDock.skipKey));
    await tap(tester, find.byKey(ListMatchDock.skipKey));
    await tap(tester, find.byKey(ListMatchSummaryActions.cartKey));
    expect(find.byType(ListMatchPage), findsNothing);
    expect(h.directory.pushes.single.itemIds, ['m']);
  });

  testWidgets('a shop with nothing for the item leaves Skip and Remove', (
    tester,
  ) async {
    await open(tester, before: (h) => h.catalogue.products = const []);
    expect(
      find.text(CheckersCopy.matchesEmptyTitle(ProductRetailer.checkers)),
      findsOneWidget,
    );
    expect(find.text(ListMatchCopy.nothingToPick), findsOneWidget);
    expect(find.byKey(ListMatchDock.nextKey), findsNothing);
    expect(find.byKey(ListMatchDock.skipKey), findsOneWidget);
    expect(dockHeight(tester), lessThan(300));
  });

  testWidgets('a search that failed says so and can be tried again', (
    tester,
  ) async {
    final h = await open(
      tester,
      before: (h) => h.catalogue.failWith = const CheckersFailure(
        CheckersProblem.catalogueBusy,
      ),
    );
    expect(
      find.text(CheckersCopy.problem(CheckersProblem.catalogueBusy)),
      findsOneWidget,
    );
    h.catalogue.failWith = null;
    await tap(tester, find.text(CheckersCopy.retry));
    expect(product('a'), findsOneWidget);
  });

  testWidgets('a refused pick is said on the page', (tester) async {
    final h = await open(tester);
    h.list.repository.failWritesWith = const PermissionDeniedFailure();
    await tap(tester, product('a'));
    await tap(tester, find.byKey(ListMatchDock.nextKey));
    expect(
      find.text(AppCopy.failure(const PermissionDeniedFailure())),
      findsOneWidget,
    );
    expect(find.text(ListMatchCopy.picked(0)), findsOneWidget);
  });

  for (final state in ['products', 'summary']) {
    testWidgets('$state, in dark at 200% on 360 wide', (tester) async {
      tester.view.physicalSize = const Size(360 * 3, 800 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await open(
        tester,
        brightness: Brightness.dark,
        scale: 2,
        fits: {'a': 0.9},
      );
      expect(find.byType(ListMatchPage), findsOneWidget);
      if (state == 'summary') {
        await tap(tester, find.byKey(ListMatchDock.nextKey));
        await tap(tester, find.byKey(ListMatchDock.skipKey));
        await tap(tester, find.byKey(ListMatchDock.removeKey));
        expect(find.byType(ListMatchSummary), findsOneWidget);
      }
      expect(dockHeight(tester), lessThan(800 * 0.6));
      expect(tester.takeException(), isNull);
    });
  }
}
