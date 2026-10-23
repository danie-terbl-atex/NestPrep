import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/grocery_plan_copy.dart';
import '../../../shared/flags/feature_flags_controller.dart';
import '../../add_to_checkers/model/retailer_switch.dart';
import '../../groceries/model/grocery_amount.dart';
import '../../groceries/model/grocery_quantity.dart';
import '../../groceries/model/product_match.dart';
import '../../household/model/household_area.dart';
import '../../household/model/household_view.dart';
import '../../subscriptions/model/premium_feature.dart';
import '../../subscriptions/state/household_entitlement.dart';
import '../../subscriptions/ui/premium_gate.dart';
import '../model/recipe_shop_line.dart';
import '../model/scaled_ingredients.dart';
import '../state/recipe_page_controller.dart';
import 'recipe_shop_sheet.dart';

/// *Add to grocer*, under a planned recipe's ingredients (recipes ADR-0005):
/// what it does, and the way in — premium, and says so before the tap
/// (subscriptions ADR-0001). Shown only once the recipe is on the family's
/// week, to somebody the `groceries` grant lets add to the list, while a
/// shop is switched on.
class RecipeShopCard extends StatelessWidget {
  const RecipeShopCard({super.key});

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final controller = context.watch<RecipePageController>();
    final mayShop = context.watch<HouseholdView>().permissions.canEdit(
      HouseholdArea.groceries,
    );
    final flags = context.watch<FeatureFlagsController?>();
    final shops = flags == null
        ? const <ProductRetailer>[]
        : shopsOn(flags.isOn);
    if (!controller.isPlanned || !mayShop || shops.isEmpty) {
      return const SizedBox.shrink();
    }
    final isPremium = context.watch<HouseholdEntitlement>().isPremium;
    final count = controller.unticked.length;
    return NestCard(
      key: const ValueKey('recipe-shop-card'),
      variant: NestCardVariant.tinted,
      padding: const EdgeInsets.all(NestSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const NestIconTile(
                icon: LucideIcons.shoppingCart,
                tint: NestTileTint.basil,
              ),
              const SizedBox(width: NestSpace.md),
              Expanded(
                child: Text(RecipeShopCopy.cardTitle, style: nest.text.title),
              ),
              if (!isPremium)
                const NestTag(
                  label: RecipeShopCopy.premiumTag,
                  tone: NestTagTone.accent,
                  icon: LucideIcons.award,
                ),
            ],
          ),
          const SizedBox(height: NestSpace.sm),
          Text(RecipeShopCopy.cardBody(count), style: nest.text.bodySecondary),
          const SizedBox(height: NestSpace.md),
          NestButton(
            key: const ValueKey('recipe-shop-open'),
            label: RecipeShopCopy.action,
            icon: LucideIcons.shoppingBasket,
            onPressed: count == 0 ? null : () => _open(context, shops),
          ),
        ],
      ),
    );
  }

  /// Premium first, then the sheet (subscriptions ADR-0001).
  static Future<void> _open(
    BuildContext context,
    List<ProductRetailer> shops,
  ) async {
    final controller = context.read<RecipePageController>();
    if (!await ensurePremium(context, feature: PremiumFeature.recipeShopping)) {
      return;
    }
    if (!context.mounted) return;
    await showRecipeShopSheet(
      context,
      householdId: controller.householdId,
      memberId: controller.memberId,
      shops: shops,
      lines: [for (final line in controller.unticked) _lineOf(line)],
    );
  }

  /// The grocery list's words for how much, as the meal plan writes them
  /// (groceries ADR-0003): a spoon or a cup is not how a shop sells it.
  static RecipeShopLine _lineOf(ScaledIngredient scaled) {
    final amount = scaled.otherUnit == null ? scaled.amount : null;
    return RecipeShopLine(
      index: scaled.index,
      name: scaled.line.name,
      quantity: amount == null
          ? null
          : GroceryPlanCopy.quantity(
              GroceryQuantity.sum([GroceryAmount(amount.value, amount.unit)]),
            ),
    );
  }
}
