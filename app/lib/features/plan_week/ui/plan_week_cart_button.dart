import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/pnp_copy.dart';
import '../../add_to_checkers/state/cart_push_controller.dart';
import '../state/plan_week_controller.dart';
import 'plan_week_pnp_push.dart';

/// *Add to my Pick n Pay cart* on the done step (lunch-box ADR-0026 §6,
/// add-to-pnp ADR-0004): the basket onto the grocery list first — matched at
/// Pick n Pay, once — then those items, with the week's packs, into the
/// member's own cart through the one cart-push flow, linking first when the
/// member has no link. A tap, never automatic.
class PlanWeekCartButton extends StatelessWidget {
  const PlanWeekCartButton({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlanWeekController>();
    final push = context.watch<CartPushController>();
    final isBusy = controller.shop.isAddingGroceries || push.isPushing;
    return NestButton(
      key: const ValueKey('plan-week-cart'),
      label: PnpCopy.addToMyCart,
      icon: LucideIcons.shoppingBasket,
      isLoading: isBusy,
      onPressed: isBusy ? null : () => _addToCart(context, controller, push),
    );
  }

  static Future<void> _addToCart(
    BuildContext context,
    PlanWeekController controller,
    CartPushController push,
  ) async {
    final entries = await controller.shop.addToGroceries(PlanWeekCopy.packs);
    if (entries == null || entries.isEmpty || !context.mounted) return;
    await pushToPnpCart(
      context,
      householdId: controller.householdId,
      push: push,
      entries: entries,
    );
  }
}
