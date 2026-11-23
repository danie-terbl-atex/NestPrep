import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/checkers_copy.dart';
import '../../../shared/copy/subscription_copy.dart';
import '../../groceries/model/grocery_item.dart';
import '../../groceries/model/product_match.dart';
import '../../groceries/state/grocery_list_controller.dart';
import '../state/product_match_controller.dart';
import '../state/retailer_choice_controller.dart';
import '../state/shop_carts.dart';
import 'add_to_shop_cart_bar.dart';
import 'list_cart_push.dart';
import 'list_match_page.dart';
import 'shops_lock.dart';

/// The grocery screen's carts (add-to-pnp ADR-0007): an action for each shop
/// switched on that has unbought items matched there — each sends only its
/// own shop's items; an item matched elsewhere is not sent — then one quiet
/// line for the unbought items nobody matched, with *Find at* the chosen
/// shop, which matches them one at a time (groceries ADR-0010).
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
              count: unmatched.length,
              isLocked: isLocked,
              onFind: () => _find(context, unmatched),
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

  /// From the bar rather than the unmatched line, which is gone by the time
  /// the page closes when everything was matched.
  Future<void> _find(BuildContext context, List<GroceryItem> unmatched) async {
    final matches = context.read<ProductMatchController>();
    final list = context.read<GroceryListController>();
    final carts = context.read<ShopCarts>();
    final shop = context.read<RetailerChoiceController>().chosen;
    if (!await ensureShops(context) || !context.mounted) return;
    matches.dismiss();
    final result = await showListMatch(
      context,
      householdId: householdId,
      memberId: matches.memberId,
      shop: shop,
      items: unmatched,
    );
    for (final item in result.removed) {
      await list.remove(item);
    }
    if (!result.wantsCart || !context.mounted) return;
    final matched = switch (list.list) {
      AsyncData(:final value) => [
        for (final item in value.toBuy)
          if (item.productMatch?.retailer == shop) item,
      ],
      _ => const <GroceryItem>[],
    };
    if (matched.isEmpty) return;
    await pushListToCart(
      context,
      shop: shop,
      householdId: householdId,
      push: carts.of(shop),
      items: matched,
    );
  }

  List<GroceryItem> _matchedAt(ProductRetailer shop) => [
    for (final item in toBuy)
      if (item.productMatch?.retailer == shop) item,
  ];
}

class _Unmatched extends StatelessWidget {
  const _Unmatched({
    required this.count,
    required this.isLocked,
    required this.onFind,
  });

  final int count;
  final bool isLocked;
  final VoidCallback onFind;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final chosen = context.watch<RetailerChoiceController>().chosen;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: NestSpace.sm,
      children: [
        Text(
          CheckersCopy.notMatched(count),
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
            onPressed: onFind,
          ),
        ),
      ],
    );
  }
}
