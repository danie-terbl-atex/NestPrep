import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/checkers_copy.dart';
import '../../groceries/model/product_match.dart';
import 'retailer_logo.dart';

/// One shop's cart action above the list: its logo, how many unbought items
/// have a product there, and *Add N to Checkers* (add-to-pnp ADR-0007).
/// Renders what it is given and reports a tap (`FE-03`).
class AddToShopCartBar extends StatelessWidget {
  const AddToShopCartBar({
    required this.shop,
    required this.matchedCount,
    required this.isPushing,
    required this.onAdd,
    super.key,
  });

  final ProductRetailer shop;
  final int matchedCount;
  final bool isPushing;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return NestCard(
      variant: NestCardVariant.tinted,
      padding: const EdgeInsets.all(NestSpace.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The words name the shop; the logo only marks it.
          RetailerLogo.decorative(retailer: shop),
          const SizedBox(width: NestSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  CheckersCopy.readyToAdd(shop, matchedCount),
                  style: nest.text.label,
                ),
                const SizedBox(height: NestSpace.sm),
                NestButton(
                  key: ValueKey('add-to-cart-${shop.code}'),
                  label: CheckersCopy.addCountTo(shop, matchedCount),
                  icon: LucideIcons.shoppingCart,
                  size: NestButtonSize.small,
                  isExpanded: false,
                  isLoading: isPushing,
                  onPressed: isPushing ? null : onAdd,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
