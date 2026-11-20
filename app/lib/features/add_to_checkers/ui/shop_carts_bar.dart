import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/checkers_copy.dart';
import '../../../shared/copy/subscription_copy.dart';
import '../../groceries/model/grocery_item.dart';
import '../../groceries/model/product_match.dart';
import '../../recipes/model/recipe_shop_line.dart';
import '../../recipes/ui/recipe_shop_sheet.dart';
import '../state/product_match_controller.dart';
import '../state/retailer_choice_controller.dart';
import '../state/shop_carts.dart';
import 'add_to_shop_cart_bar.dart';
import 'list_cart_push.dart';
import 'shops_lock.dart';

/// The grocery screen's carts (add-to-pnp ADR-0007): an action for each shop
/// switched on that has unbought items matched there — each sends only its
/// own shop's items; an item matched elsewhere is not sent — then one quiet
/// line for the unbought items nobody matched, with *Find at* the chosen
/// shop, which looks for all of them at once (groceries ADR-0009).
class ShopCartsBar extends StatelessWidget {
  const ShopCartsBar({
    required this.householdId,
    required this.toBuy,
    required this.shops,
    super.key,
  });

  final String householdId;
  final List<GroceryItem> toBuy;

  /// The shops switched on, in their order.
  final List<ProductRetailer> shops;

  @override
  Widget build(BuildContext context) {
    final carts = context.read<ShopCarts>();
    final isLocked = !shopsUnlocked(context);
    final unmatched = [
      for (final item in toBuy)
        if (item.productMatch == null) item,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final shop in shops)
          if (_matchedAt(shop) case final items when items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: NestSpace.md),
              child: ListenableBuilder(
                listenable: carts.of(shop),
                builder: (context, _) => AddToShopCartBar(
                  shop: shop,
                  matchedCount: items.length,
                  isPushing: carts.of(shop).isPushing,
                  isLocked: isLocked,
                  onAdd: () => _push(context, carts, shop, items),
                ),
              ),
            ),
        if (unmatched.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: NestSpace.lg),
            child: _Unmatched(
              householdId: householdId,
              items: unmatched,
              shops: shops,
              isLocked: isLocked,
            ),
          ),
      ],
    );
  }

  Future<void> _push(
    BuildContext context,
    ShopCarts carts,
    ProductRetailer shop,
    List<GroceryItem> items,
  ) async {
    if (!await ensureShops(context) || !context.mounted) return;
    await pushListToCart(
      context,
      shop: shop,
      householdId: householdId,
      push: carts.of(shop),
      items: items,
    );
  }

  List<GroceryItem> _matchedAt(ProductRetailer shop) => [
    for (final item in toBuy)
      if (item.productMatch?.retailer == shop) item,
  ];
}

class _Unmatched extends StatelessWidget {
  const _Unmatched({
    required this.householdId,
    required this.items,
    required this.shops,
    required this.isLocked,
  });

  final String householdId;
  final List<GroceryItem> items;
  final List<ProductRetailer> shops;
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final chosen = context.watch<RetailerChoiceController>().chosen;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: NestSpace.sm,
      children: [
        Text(
          CheckersCopy.notMatched(items.length),
          style: nest.text.caption.copyWith(color: nest.colors.inkSecondary),
        ),
        Semantics(
          hint: isLocked ? SubscriptionCopy.lockedHint : null,
          child: NestButton(
            key: const ValueKey('find-unmatched'),
            label: CheckersCopy.findAt(chosen),
            icon: isLocked ? LucideIcons.lock : null,
            variant: NestButtonVariant.ghost,
            size: NestButtonSize.small,
            isExpanded: false,
            onPressed: () => _find(context),
          ),
        ),
      ],
    );
  }

  Future<void> _find(BuildContext context) async {
    final matches = context.read<ProductMatchController>();
    if (!await ensureShops(context) || !context.mounted) return;
    matches.dismiss();
    await showRecipeShopSheet(
      context,
      householdId: householdId,
      memberId: matches.memberId,
      shops: shops,
      purpose: RecipeShopPurpose.match,
      lines: [
        for (final (index, item) in items.indexed)
          RecipeShopLine(
            index: index,
            name: item.name,
            quantity: item.quantity,
          ),
      ],
    );
  }
}
