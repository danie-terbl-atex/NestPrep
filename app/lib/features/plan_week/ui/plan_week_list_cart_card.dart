import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/failure/app_failure.dart';
import '../../add_to_checkers/state/cart_push_controller.dart';
import '../../add_to_checkers/state/shop_carts.dart';
import '../../add_to_checkers/ui/shop_cart_push.dart';
import '../../groceries/model/product_match.dart';
import '../model/packs_in_quantity.dart';
import '../model/shop_list_entry.dart';
import '../state/plan_week_controller.dart';

/// The brief's way back to the cart (lunch-box ADR-0027): the unbought items
/// on the grocery list already matched at the brief's shop, pushed into the
/// member's own cart there through the same push as the done step — for a week
/// used earlier whose push failed, whose link ran out, or whose done step
/// was left. A push, never matching.
class PlanWeekListCartCard extends StatefulWidget {
  const PlanWeekListCartCard({super.key});

  @override
  State<PlanWeekListCartCard> createState() => _PlanWeekListCartCardState();
}

class _PlanWeekListCartCardState extends State<PlanWeekListCartCard> {
  bool _isReading = false;
  bool _hasNone = false;
  AppFailure? _failure;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final shop = context.watch<PlanWeekController>().retailer.shop;
    final push = context.read<ShopCarts>().of(shop);
    return NestCard(
      key: const ValueKey('plan-week-list-cart'),
      variant: NestCardVariant.flat,
      padding: const EdgeInsets.all(NestSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(PlanWeekAgainCopy.listCartTitle(shop), style: nest.text.title),
          const SizedBox(height: NestSpace.xs),
          Text(
            PlanWeekAgainCopy.listCartBody(shop),
            style: nest.text.bodySecondary,
          ),
          const SizedBox(height: NestSpace.md),
          ListenableBuilder(
            listenable: push,
            builder: (context, _) {
              final isBusy = _isReading || push.isPushing;
              return NestButton(
                key: const ValueKey('plan-week-list-cart-push'),
                label: PlanWeekAgainCopy.listCartAction(shop),
                icon: LucideIcons.shoppingBasket,
                variant: NestButtonVariant.tonal,
                isLoading: isBusy,
                onPressed: isBusy ? null : () => _push(shop, push),
              );
            },
          ),
          if (_hasNone) ...[
            const SizedBox(height: NestSpace.sm),
            Text(
              PlanWeekAgainCopy.listCartNone(shop),
              style: nest.text.bodySecondary,
            ),
          ],
          if (_failure case final failure?) ...[
            const SizedBox(height: NestSpace.sm),
            NestBanner(
              message: AppCopy.failure(failure),
              tone: NestBannerTone.danger,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _push(ProductRetailer shop, CartPushController push) async {
    final controller = context.read<PlanWeekController>();
    setState(() {
      _isReading = true;
      _hasNone = false;
      _failure = null;
    });
    List<ShopListEntry> entries;
    try {
      entries = await controller.shop.waitingOnList(shop, packsInQuantity);
    } on AppFailure catch (failure) {
      if (mounted) {
        setState(() {
          _isReading = false;
          _failure = failure;
        });
      }
      return;
    }
    if (!mounted) return;
    setState(() {
      _isReading = false;
      _hasNone = entries.isEmpty;
    });
    if (entries.isEmpty) return;
    await pushToShopCart(
      context,
      shop: shop,
      householdId: controller.householdId,
      push: push,
      entries: entries,
    );
  }
}
