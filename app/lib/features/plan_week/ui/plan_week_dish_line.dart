import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../groceries/model/product_match.dart';
import '../../recipes/ui/recipe_sheet.dart';
import '../model/dish_draft.dart';

/// Under a drafted main on the ideas list (lunch-box ADR-0021 §3): what its
/// recipe uses, and *How to make it* — the recipe sheet, from the draft,
/// before anything is saved.
class PlanWeekDishLine extends StatelessWidget {
  const PlanWeekDishLine({required this.dish, required this.shop, super.key});

  final DishDraft dish;

  /// The shop each ingredient is searched at.
  final ProductRetailer shop;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: NestSpace.xs),
      child: Wrap(
        spacing: NestSpace.sm,
        runSpacing: NestSpace.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            PlanWeekCopy.dishMadeWith(dish.ingredients.length, shop),
            style: nest.text.caption,
          ),
          NestButton(
            label: RecipeCopy.howToMakeShort,
            icon: LucideIcons.chefHat,
            variant: NestButtonVariant.ghost,
            size: NestButtonSize.medium,
            isExpanded: false,
            onPressed: () => showRecipeSheet(context, dish.toRecipe()),
          ),
        ],
      ),
    );
  }
}
