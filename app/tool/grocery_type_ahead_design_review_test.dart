import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/add_to_checkers/state/product_match_controller.dart';
import 'package:nestprep/features/add_to_checkers/state/product_type_ahead_controller.dart';
import 'package:nestprep/features/add_to_checkers/state/retailer_choice_controller.dart';
import 'package:nestprep/features/add_to_checkers/state/shop_carts.dart';
import 'package:nestprep/features/groceries/state/grocery_list_controller.dart';
import 'package:nestprep/features/groceries/ui/grocery_list_screen.dart';
import 'package:nestprep/shared/flags/feature_flags_controller.dart';
import 'package:provider/provider.dart';

import '../test/support/checkers_grocery_harness.dart';
import '../test/support/fake_checkers.dart';
import '../test/support/fake_feature_flag_source.dart';
import '../test/support/grocery_list_harness.dart';
import 'review_press.dart';

/// Matching as you type on the grocery list (add-to-checkers ADR-0007): the
/// shop's logo at the start of the add field, and *milk* typed with what
/// Checkers sells for it leading the list, Jev's best first. `flutter test
/// tool/grocery_type_ahead_design_review_test.dart --update-goldens` retakes
/// them.
void main() {
  setUpAll(loadEveryFont);

  for (final (brightness, textScale, name) in [
    (Brightness.light, 1.0, 'groceries-match-as-you-type-light'),
    (Brightness.dark, 1.0, 'groceries-match-as-you-type-dark'),
    (Brightness.dark, 2.0, 'groceries-match-as-you-type-dark-200-percent-text'),
  ]) {
    testWidgets(name, (tester) async {
      final h = CheckersGroceryHarness();
      h.catalogue.products = [
        checkersProduct('Clover Fresh Full Cream Milk 2L', oldCents: 4299),
        checkersProduct(
          'Darling Fresh Full Cream Milk 2L',
          id: '5db2b6a9280e5b57ebe9a222',
          brand: 'Darling',
          cents: 3299,
          isOnPromotion: true,
        ),
        checkersProduct(
          'Checkers Housebrand Low Fat Milk 1L',
          id: '5db2b6a9280e5b57ebe9a333',
          brand: 'Checkers',
          cents: 1899,
        ),
      ];
      h.ranker.fits = {'5d3af63bf434cf8420737dd6': 0.92};
      await captureScreen(
        tester,
        name,
        screen: GroceryListScreen(onSelectTab: (_) {}),
        providers: [
          ChangeNotifierProvider<GroceryListController>.value(
            value: h.list.controller,
          ),
          h.list.plans.provider,
          ChangeNotifierProvider<ProductMatchController>.value(
            value: h.matches,
          ),
          ChangeNotifierProvider<ProductTypeAheadController>.value(
            value: h.typeAhead,
          ),
          Provider<ShopCarts>.value(
            value: ShopCarts(checkers: h.push, pickNPay: h.pnpPush),
          ),
          ChangeNotifierProvider<RetailerChoiceController>.value(
            value: h.retailers,
          ),
          ChangeNotifierProvider<FeatureFlagsController>(
            create: (_) => testFlagsController(TestFlags.on),
          ),
        ],
        brightness: brightness,
        textScale: textScale,
        emit: () async => h.list.repository.emitItems([
          groceryItem('Bread', id: 'bread'),
          groceryItem('Eggs', id: 'eggs'),
        ]),
        act: () => tester.enterText(find.byType(TextField), 'milk'),
      );
    });
  }
}
