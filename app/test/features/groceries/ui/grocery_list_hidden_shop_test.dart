import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/add_to_checkers/ui/find_at_checkers_button.dart';
import 'package:nestprep/features/add_to_checkers/ui/product_match_line.dart';
import 'package:nestprep/features/groceries/model/grocery_item.dart';
import 'package:nestprep/shared/flags/feature_flag.dart';

import '../../../support/checkers_grocery_harness.dart';
import '../../../support/grocery_list_harness.dart';
import '../../../support/household_fixtures.dart';

/// A shop waiting to go live is not offered (shops ADR-0002), and neither is
/// anything it left behind: a product once picked there is not shown, by
/// name or by mark, and its item is offered to the shops that are on.
void main() {
  final matched = GroceryItem(
    id: 'matched',
    name: 'Full cream milk',
    addedBy: Fixtures.samMemberId,
    addedAt: groceryNow,
    productMatch: pickedMilk,
  );

  testWidgets('a pick at a switched-off shop is not shown', (tester) async {
    final h = CheckersGroceryHarness();
    await h.pump(tester, off: {FeatureFlag.checkersShop});
    h.list.repository.emitItems([matched]);
    await tester.pumpAndSettle();

    expect(find.text('Full cream milk'), findsOneWidget);
    expect(find.byType(ProductMatchLine), findsNothing);
    expect(find.byType(FindAtCheckersButton), findsOneWidget);
  });

  testWidgets('and is shown again once its shop is on', (tester) async {
    final h = CheckersGroceryHarness();
    await h.pump(tester);
    h.list.repository.emitItems([matched]);
    await tester.pumpAndSettle();

    expect(find.byType(ProductMatchLine), findsOneWidget);
  });
}
