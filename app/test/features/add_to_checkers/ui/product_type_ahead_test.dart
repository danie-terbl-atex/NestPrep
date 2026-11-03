import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/groceries/model/product_match.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/checkers_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/bring_into_view.dart';
import '../../../support/checkers_grocery_harness.dart';
import '../../../support/household_fixtures.dart';

/// The chosen shop's products while a grocery name is typed
/// (add-to-checkers ADR-0007): one tap adds the item already matched, and
/// nothing about it holds a plain add up.
void main() {
  const checkers = ProductRetailer.checkers;
  final field = find.byType(TextField);

  Future<CheckersGroceryHarness> open(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    double scale = 1,
  }) async {
    final h = CheckersGroceryHarness();
    await h.pump(tester, brightness: brightness, scale: scale);
    h.list.repository.emitItems(const []);
    await tester.pumpAndSettle();
    return h;
  }

  Future<void> type(WidgetTester tester, String text) async {
    await tester.enterText(field, text);
    await tester.pumpAndSettle();
  }

  testWidgets('typing a name shows what the shop sells for it', (tester) async {
    final h = await open(tester);
    await type(tester, 'milk');

    expect(find.text(CheckersCopy.typeAheadTitle(checkers, 'milk')), findsOne);
    expect(find.text('Clover Fresh Full Cream Milk 2L'), findsOneWidget);
    expect(find.text('Darling Fresh Full Cream Milk 2L'), findsOneWidget);
    expect(h.catalogue.searches.single.query, 'milk');
  });

  testWidgets('fewer than three letters asks nothing', (tester) async {
    final h = await open(tester);
    await type(tester, 'mi');

    expect(
      find.text(CheckersCopy.typeAheadTitle(checkers, 'mi')),
      findsNothing,
    );
    expect(h.catalogue.searches, isEmpty);
  });

  testWidgets('adding a product puts the typed name on the list with it', (
    tester,
  ) async {
    final h = await open(tester);
    await type(tester, 'milk');
    await tester.tap(find.text('Clover Fresh Full Cream Milk 2L'));
    await tester.pumpAndSettle();

    final added = h.list.repository.addedMatched.single;
    expect(added.name, 'milk');
    expect(added.match.productId, '5d3af63bf434cf8420737dd6');
    expect(added.match.pickedBy, Fixtures.samMemberId);
    expect(tester.widget<TextField>(field).controller!.text, isEmpty);
    expect(
      find.text(CheckersCopy.typeAheadTitle(checkers, 'milk')),
      findsNothing,
    );
  });

  testWidgets('*Just add* adds the name alone and opens no panel', (
    tester,
  ) async {
    final h = await open(tester);
    await type(tester, 'milk');
    await bringIntoView(tester, find.text(CheckersCopy.justAdd('milk')));
    await tester.tap(find.text(CheckersCopy.justAdd('milk')));
    await tester.pumpAndSettle();

    expect(h.list.repository.added.single.name, 'milk');
    expect(h.list.repository.addedMatched, isEmpty);
    expect(h.matches.target, isNull);
  });

  testWidgets('the field\'s own add still adds at once and looks after', (
    tester,
  ) async {
    final h = await open(tester);
    await type(tester, 'milk');
    await tester.tap(find.byTooltip(AppCopy.groceriesAdd));
    await tester.pumpAndSettle();

    expect(h.list.repository.added.single.name, 'milk');
    expect(h.list.repository.addedMatched, isEmpty);
    expect(h.matches.target?.name, 'milk');
  });

  testWidgets('a shop that fails says so and offers a retry', (tester) async {
    final h = await open(tester);
    h.catalogue.failWith = const CheckersFailure(CheckersProblem.catalogueBusy);
    await type(tester, 'milk');

    expect(find.text(CheckersCopy.retry), findsOneWidget);
    expect(find.text(CheckersCopy.justAdd('milk')), findsOneWidget);

    h.catalogue.failWith = null;
    await bringIntoView(tester, find.text(CheckersCopy.retry));
    await tester.tap(find.text(CheckersCopy.retry));
    await tester.pumpAndSettle();
    expect(find.text('Clover Fresh Full Cream Milk 2L'), findsOneWidget);
  });

  testWidgets('turned off, typing shows nothing', (tester) async {
    final h = await open(tester);
    h.retailers.setMatchesAsYouType(isOn: false);
    await type(tester, 'milk');

    expect(h.catalogue.searches, isEmpty);
    expect(
      find.text(CheckersCopy.typeAheadTitle(checkers, 'milk')),
      findsNothing,
    );
  });

  testWidgets('fits a phone at 200% text in the dark, products showing', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 780));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await open(tester, brightness: Brightness.dark, scale: 2);
    await type(tester, 'milk');

    expect(tester.takeException(), isNull);
    expect(find.text(CheckersCopy.typeAheadTitle(checkers, 'milk')), findsOne);
  });
}
