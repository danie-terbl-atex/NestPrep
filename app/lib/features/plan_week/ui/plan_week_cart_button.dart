import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/cart_push_copy.dart';
import '../../add_to_checkers/state/shop_carts.dart';
import '../../add_to_checkers/ui/shop_cart_push.dart';
import '../state/plan_week_controller.dart';

/// *Add to my … cart* on the done step (lunch-box ADR-0026 §6, add-to-pnp
/// ADR-0004): the basket onto the grocery list first — matched at the shop
/// the week was planned at, once — then those items into the member's own
/// cart there through the one cart-push flow, linking first when the member
/// has no link. A tap, never automatic.
class PlanWeekCartButton extends StatelessWidget {
  const PlanWeekCartButton({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlanWeekController>();
    final shop = controller.retailer.shop;
    final push = context.read<ShopCarts>().of(shop);
    return ListenableBuilder(
      listenable: push,
      builder: (context, _) {
        final isBusy = controller.shop.isAddingGroceries || push.isPushing;
        return NestButton(
          key: const ValueKey('plan-week-cart'),
          label: CartPushCopy.addToMyCart(shop),
          icon: LucideIcons.shoppingBasket,
          isLoading: isBusy,
          onPressed: isBusy ? null : () => _addToCart(context, controller),
        );
      },
    );
  }

  static Future<void> _addToCart(
    BuildContext context,
    PlanWeekController controller,
  ) async {
    final shop = controller.retailer.shop;
    final push = context.read<ShopCarts>().of(shop);
    final entries = await controller.shop.addToGroceries(PlanWeekCopy.packs);
    if (entries == null || entries.isEmpty || !context.mounted) return;
    await pushToShopCart(
      context,
      shop: shop,
      householdId: controller.householdId,
      push: push,
      entries: entries,
    );
  }
}
