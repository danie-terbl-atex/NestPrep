import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/groceries/model/grocery_item.dart';
import 'package:nestprep/features/groceries/state/grocery_list_controller.dart';
import 'package:nestprep/features/groceries/ui/grocery_item_sheet.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_grocery_repository.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';

/// Renaming and removing one thing on the list. It was at zero.
void main() {
  final now = DateTime.utc(2026, 9, 18, 6);

  late FakeGroceryRepository repository;
  late GroceryListController controller;

  setUp(() {
    repository = FakeGroceryRepository();
    controller = GroceryListController(
      groceryRepository: repository,
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
      now: () => now,
    );
  });

  tearDown(() async {
    controller.dispose();
    await repository.close();
  });

  final milk = GroceryItem(
    id: 'g1',
    name: 'Milk',
    quantity: '2 litres',
    addedBy: Fixtures.samMemberId,
    addedAt: now,
  );

  Finder fieldLabelled(String label) => find.descendant(
    of: find.ancestor(
      of: find.text(label),
      matching: find.byType(NestTextField),
    ),
    matching: find.byType(TextField),
  );

  Future<void> open(WidgetTester tester) async {
    await pumpScreen(
      tester,
      Builder(
        builder: (context) => NestButton(
          label: 'open',
          onPressed: () => showGroceryItemSheet(context: context, item: milk),
        ),
      ),
      providers: [
        ChangeNotifierProvider<GroceryListController>.value(value: controller),
      ],
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('opens on what the item already says', (tester) async {
    await open(tester);

    expect(find.text(AppCopy.groceriesEditItem), findsWidgets);
    expect(
      tester
          .widget<TextField>(fieldLabelled(AppCopy.groceriesAddHint))
          .controller
          ?.text,
      'Milk',
    );
    expect(
      tester
          .widget<TextField>(fieldLabelled(AppCopy.groceriesQuantityHint))
          .controller
          ?.text,
      '2 litres',
    );
  });

  testWidgets('a new name and quantity are saved, and the sheet closes', (
    tester,
  ) async {
    await open(tester);

    await tester.enterText(
      fieldLabelled(AppCopy.groceriesAddHint),
      'Full cream milk',
    );
    await tester.enterText(
      fieldLabelled(AppCopy.groceriesQuantityHint),
      '3 litres',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(NestButton, AppCopy.householdSave));
    await tester.pumpAndSettle();

    final renamed = repository.renamed.single;
    expect(renamed.itemId, 'g1');
    expect(renamed.name, 'Full cream milk');
    expect(renamed.quantity, '3 litres');
    expect(
      find.text(AppCopy.groceriesEditItem),
      findsNothing,
      reason: 'saving closes the sheet',
    );
  });

  testWidgets('clearing the quantity takes it off the item', (tester) async {
    await open(tester);

    await tester.enterText(fieldLabelled(AppCopy.groceriesQuantityHint), '');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(NestButton, AppCopy.householdSave));
    await tester.pumpAndSettle();

    expect(
      repository.renamed.single.quantity,
      isNull,
      reason: 'an empty box means no quantity, not a quantity of ""',
    );
  });

  testWidgets('removing takes it off the list and closes', (tester) async {
    await open(tester);

    await tester.tap(find.widgetWithText(NestButton, AppCopy.householdRemove));
    await tester.pumpAndSettle();

    expect(repository.removed, ['g1']);
    expect(find.text(AppCopy.groceriesEditItem), findsNothing);
  });
}
