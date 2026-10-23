import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../add_to_checkers/model/retailer_product.dart';
import '../../add_to_checkers/ui/checkers_product_tile.dart';
import '../model/recipe_shop_line.dart';

/// The other products the shop answered for one ingredient, to pick a
/// different one to buy — each as the grocery list shows a match. Answers
/// the product picked, or null when the sheet was closed. A product a cart
/// cannot take (out of stock, sold by weight) is shown but not offered.
Future<RetailerProduct?> showRecipeProductChoice({
  required BuildContext context,
  required RecipeShopLine line,
}) => showNestSheet<RetailerProduct>(
  context: context,
  title: RecipeShopCopy.changeTitle(line.name),
  builder: (context) => ListView.separated(
    shrinkWrap: true,
    padding: const EdgeInsets.only(bottom: NestSpace.xl),
    itemCount: line.products.length,
    separatorBuilder: (_, _) => const SizedBox(height: NestSpace.lg),
    itemBuilder: (context, index) {
      final product = line.products[index];
      return CheckersProductTile(
        key: ValueKey('recipe-shop-choice-${product.id}'),
        product: product,
        onPick: RecipeShopLine.isBuyable(product)
            ? () => Navigator.of(context).pop(product)
            : null,
      );
    },
  ),
);
