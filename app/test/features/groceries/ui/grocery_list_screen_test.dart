import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/groceries/model/grocery_item.dart';
import 'package:nestprep/features/groceries/state/grocery_list_controller.dart';
import 'package:nestprep/features/groceries/ui/grocery_list_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_grocery_repository.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';

final _now = DateTime.utc(2026, 9, 17, 12);

GroceryItem item(String name, {String id = 'i', DateTime? boughtAt}) =>
    GroceryItem(
      id: id,
      name: name,
      addedBy: Fixtures.samMemberId,
      addedAt: _now,
      boughtAt: boughtAt,
      boughtBy: boughtAt == null ? null : Fixtures.samMemberId,
    );

void main() {
  late FakeGroceryRepository repository;
  late GroceryListController controller;

  setUp(() {
    repository = FakeGroceryRepository();
    controller = GroceryListController(
      groceryRepository: repository,
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
      now: () => _now,
    );
  });

  tearDown(() async {
    controller.dispose();
    await repository.close();
  });

  Future<void> pump(
    WidgetTester tester, {
    Brightness? brightness,
    double scale = 1,
  }) => pumpScreen(
    tester,
    GroceryListScreen(onSelectTab: (_) {}),
    providers: [
      ChangeNotifierProvider<GroceryListController>.value(value: controller),
    ],
    brightness: brightness ?? Brightness.light,
    textScale: scale,
  );

  testWidgets('holds the layout while it loads rather than collapsing', (
    tester,
  ) async {
    await pump(tester);
    await tester.pump();
    expect(find.text(AppCopy.groceriesTitle), findsOneWidget);
    expect(find.text(AppCopy.groceriesEmptyTitle), findsNothing);
  });

  testWidgets('says what to do next when the list is empty', (tester) async {
    await pump(tester);
    repository.emitItems([...[], ...[]]);
    await tester.pumpAndSettle();

    expect(find.text(AppCopy.groceriesEmptyTitle), findsOneWidget);
    expect(find.text(AppCopy.groceriesEmptyBody), findsOneWidget);
  });

  testWidgets('shows human copy and a way back when the read fails', (
    tester,
  ) async {
    await pump(tester);
    repository.failItemsWith(const UnavailableFailure());
    await tester.pumpAndSettle();

    expect(
      find.text(AppCopy.failure(const UnavailableFailure())),
      findsOneWidget,
    );
    expect(find.text(AppCopy.retry), findsOneWidget);
  });

  testWidgets('lists what is to buy and what was just bought', (tester) async {
    await pump(tester);
    repository.emitItems([
      ...[item('Milk', id: 'milk')],
      ...[
        item(
          'Bread',
          id: 'bread',
          boughtAt: _now.subtract(const Duration(hours: 1)),
        ),
      ],
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
    await pump(tester);
    repository.emitItems([
      ...[item('Milk', id: 'milk')],
      ...[],
    ]);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Milk'));
    await tester.pumpAndSettle();

    expect(repository.ticked.single.itemId, 'milk');
    expect(repository.ticked.single.isBought, isTrue);
  });

  testWidgets('a chip adds the item again in one tap', (tester) async {
    await pump(tester);
    repository.emitItems([
      ...[],
      ...[
        item('Milk', id: 'a', boughtAt: _now.subtract(const Duration(days: 3))),
      ],
    ]);
    await tester.pumpAndSettle();

    expect(find.text(AppCopy.groceriesOften), findsOneWidget);
    expect(find.text(AppCopy.groceriesEmptyTitle), findsOneWidget);
    await tester.tap(find.text('Milk'));
    await tester.pumpAndSettle();

    expect(repository.added.single.name, 'Milk');
  });

  testWidgets('typing a name and submitting adds it and clears the field', (
    tester,
  ) async {
    await pump(tester);
    repository.emitItems([...[], ...[]]);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Eggs');
    await tester.pumpAndSettle();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(repository.added.single.name, 'Eggs');
    expect(find.text('Eggs'), findsNothing);
  });

  testWidgets('a refused write shows copy, never an error code', (
    tester,
  ) async {
    await pump(tester);
    repository.emitItems([
      ...[item('Milk', id: 'milk')],
      ...[],
    ]);
    await tester.pumpAndSettle();

    repository.failWritesWith = const PermissionDeniedFailure();
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

    await pump(tester, brightness: Brightness.dark, scale: 2);
    repository.emitItems([
      ...[item('Full cream milk', id: 'milk')],
      ...[],
    ]);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Full cream milk'), findsOneWidget);
  });
}
