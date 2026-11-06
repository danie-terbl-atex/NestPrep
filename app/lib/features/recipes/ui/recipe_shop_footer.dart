import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../add_to_checkers/state/shop_carts.dart';
import '../../add_to_checkers/ui/shop_cart_push.dart';
import '../state/recipe_shop_controller.dart';

/// What *Add to grocer* does with what it found (recipes ADR-0005): about
/// what it costs, then the lines straight into the member's own cart at the
/// shop — on the grocery list first, as every cart push is — or only onto
/// the list. A tap, never automatic. Once on the list it says how many went
/// on, and the cart stays one tap away.
class RecipeShopFooter extends StatelessWidget {
  const RecipeShopFooter({required this.householdId, super.key});

  final String householdId;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final controller = context.watch<RecipeShopController>();
    final shop = controller.shop;
    if (shop == null) return const SizedBox.shrink();
    final push = context.read<ShopCarts>().of(shop);
    final estimate = controller.estimate;
    final added = controller.addedCount;
    final count = controller.includedCount;
    final canAdd = controller.isSettled && count > 0;
    final failure = controller.actionFailure;
    return ListenableBuilder(
      listenable: push,
      builder: (context, _) {
        final isBusy = controller.isAdding || push.isPushing;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (failure != null) ...[
              NestBanner(
                message: AppCopy.failure(failure),
                tone: NestBannerTone.danger,
                actionLabel: AppCopy.back,
                onAction: controller.dismissActionFailure,
              ),
              const SizedBox(height: NestSpace.md),
            ],
            if (added != null) ...[
              Semantics(
                liveRegion: true,
                child: NestBanner(
                  message: RecipeShopCopy.added(added),
                  tone: NestBannerTone.success,
                ),
              ),
              const SizedBox(height: NestSpace.md),
            ] else if (controller.isSettled) ...[
              Text(
                count == 0
                    ? RecipeShopCopy.nothingIncluded
                    : estimate == null
                    ? ''
                    : RecipeShopCopy.estimate(estimate, shop),
                style: nest.text.caption,
              ),
              const SizedBox(height: NestSpace.sm),
            ],
            if (controller.listed?.isEmpty != true)
              NestButton(
                key: const ValueKey('recipe-shop-cart'),
                label: RecipeShopCopy.addToCart(shop),
                icon: LucideIcons.shoppingBasket,
                isLoading: isBusy,
                onPressed: canAdd && !isBusy ? () => _toCart(context) : null,
              ),
            const SizedBox(height: NestSpace.sm),
            if (added == null)
              NestButton(
                key: const ValueKey('recipe-shop-list'),
                label: RecipeShopCopy.addToList(count),
                icon: LucideIcons.listPlus,
                variant: NestButtonVariant.tonal,
                isLoading: controller.isAdding,
                onPressed: canAdd && !isBusy ? controller.addToList : null,
              )
            else
              NestButton(
                label: RecipeShopCopy.done,
                variant: NestButtonVariant.ghost,
                onPressed: () => Navigator.of(context).pop(),
              ),
          ],
        );
      },
    );
  }

  Future<void> _toCart(BuildContext context) async {
    final controller = context.read<RecipeShopController>();
    final shop = controller.shop;
    if (shop == null || !await controller.addToList()) return;
    final entries = controller.listed;
    if (entries == null || entries.isEmpty || !context.mounted) return;
    await pushToShopCart(
      context,
      shop: shop,
      householdId: householdId,
      push: context.read<ShopCarts>().of(shop),
      entries: entries,
    );
  }
}
