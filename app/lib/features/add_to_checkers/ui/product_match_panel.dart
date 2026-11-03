import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/checkers_copy.dart';
import '../model/retailer_product.dart';
import '../state/product_match_controller.dart';
import 'checkers_area_sheet.dart';
import 'checkers_product_tile.dart';
import 'products_message.dart';

/// The Checkers matches under the item they are for: loading, nothing close,
/// a failure with a retry, or up to five products to pick from (`FE-08`).
/// Inline rather than full-screen, so the list stays where it was.
class ProductMatchPanel extends StatelessWidget {
  const ProductMatchPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProductMatchController>();
    final target = controller.target;
    if (target == null) return const SizedBox.shrink();
    final nest = NestTheme.of(context);
    return NestCard(
      variant: NestCardVariant.tinted,
      padding: const EdgeInsets.all(NestSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  CheckersCopy.matchesTitle(target.shop, target.name),
                  style: nest.text.bodyStrong,
                ),
              ),
              NestIconButton(
                icon: LucideIcons.x,
                label: CheckersCopy.closeMatches,
                variant: NestIconButtonVariant.plain,
                onPressed: controller.dismiss,
              ),
            ],
          ),
          _PlaceLine(controller: controller),
          const SizedBox(height: NestSpace.sm),
          switch (controller.matches) {
            AsyncLoading() => ProductsLoading(shop: target.shop),
            AsyncFailure(:final failure) => ProductsMessage(
              message: AppCopy.failure(failure),
              actionLabel: CheckersCopy.retry,
              onAction: controller.retry,
            ),
            AsyncData(value: final products) when products.isEmpty =>
              ProductsMessage(
                title: CheckersCopy.matchesEmptyTitle(target.shop),
                message: CheckersCopy.matchesEmptyBody(target.shop),
              ),
            AsyncData(value: final products) => _Products(
              products: products,
              bestMatchId: controller.bestMatchId,
              onPick: controller.isPicking ? null : controller.pick,
            ),
          },
        ],
      ),
    );
  }
}

class _PlaceLine extends StatelessWidget {
  const _PlaceLine({required this.controller});

  final ProductMatchController controller;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final place = controller.place;
    final area = place?.area;
    final label = switch (place) {
      null => CheckersCopy.matchesLoading(controller.target!.shop),
      _ when area != null => CheckersCopy.nearArea(area.label),
      _ => CheckersCopy.nearYou,
    };
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: NestSpace.sm,
      children: [
        Text(
          label,
          style: nest.text.caption.copyWith(color: nest.colors.inkSecondary),
        ),
        NestButton(
          label: CheckersCopy.changeArea,
          variant: NestButtonVariant.ghost,
          size: NestButtonSize.small,
          isExpanded: false,
          onPressed: () => showCheckersAreaSheet(
            context: context,
            current: area,
            onChoose: controller.chooseArea,
          ),
        ),
      ],
    );
  }
}

class _Products extends StatelessWidget {
  const _Products({
    required this.products,
    required this.bestMatchId,
    required this.onPick,
  });

  final List<RetailerProduct> products;
  final String? bestMatchId;
  final ValueChanged<RetailerProduct>? onPick;

  @override
  Widget build(BuildContext context) {
    final pick = onPick;
    return Column(
      children: [
        for (final (index, product) in products.indexed) ...[
          if (index > 0) const SizedBox(height: NestSpace.md),
          CheckersProductTile(
            key: ValueKey('${product.storeId}/${product.id}'),
            product: product,
            isBestMatch: product.id == bestMatchId,
            onPick: pick == null ? null : () => pick(product),
          ),
        ],
      ],
    );
  }
}
