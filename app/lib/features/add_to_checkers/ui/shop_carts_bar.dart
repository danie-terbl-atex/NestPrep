import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/checkers_copy.dart';
import '../../groceries/model/grocery_item.dart';
import '../../groceries/model/product_match.dart';
import '../state/product_match_controller.dart';
import '../state/retailer_choice_controller.dart';
import '../state/shop_carts.dart';
import 'add_to_shop_cart_bar.dart';
import 'list_cart_push.dart';

/// The grocery screen's carts (add-to-pnp ADR-0007): an action for each shop
/// switched on that has unbought items matched there — each sends only its
/// own shop's items; an item matched elsewhere is not sent — then one quiet
/// line for the unbought items nobody matched, with *Find at* the chosen
/// shop, which opens the first of them.
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
                  onAdd: () => pushListToCart(
                    context,
                    shop: shop,
                    householdId: householdId,
                    push: carts.of(shop),
                    items: items,
                  ),
                ),
              ),
            ),
        if (unmatched.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: NestSpace.lg),
            child: _Unmatched(first: unmatched.first, count: unmatched.length),
          ),
      ],
    );
  }

  List<GroceryItem> _matchedAt(ProductRetailer shop) => [
    for (final item in toBuy)
      if (item.productMatch?.retailer == shop) item,
  ];
}

class _Unmatched extends StatelessWidget {
  const _Unmatched({required this.first, required this.count});

  final GroceryItem first;
  final int count;

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
        NestButton(
          key: const ValueKey('find-unmatched'),
          label: CheckersCopy.findAt(chosen),
          variant: NestButtonVariant.ghost,
          size: NestButtonSize.small,
          isExpanded: false,
          onPressed: () =>
              context.read<ProductMatchController>().lookFor(first, at: chosen),
        ),
      ],
    );
  }
}
