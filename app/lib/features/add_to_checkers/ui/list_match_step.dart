import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/checkers_copy.dart';
import '../../../shared/copy/list_match_copy.dart';
import '../model/retailer_product.dart';
import '../state/list_match_controller.dart';
import 'checkers_area_sheet.dart';
import 'products_message.dart';
import 'retailer_product_image.dart';

/// One grocery item and the shop's products for it, to pick one from.
class ListMatchStep extends StatelessWidget {
  const ListMatchStep({super.key});

  static const tileWidth = 150.0;
  static const skeletonHeight = 200.0;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final controller = context.watch<ListMatchController>();
    final item = controller.item;
    if (item == null) return const SizedBox.shrink();
    final quantity = item.quantity?.trim();
    final area = controller.place?.area;
    final where = switch (controller.place) {
      null => CheckersCopy.matchesLoading(controller.shop),
      _ when area != null => CheckersCopy.nearArea(area.label),
      _ => CheckersCopy.nearYou,
    };
    return ListView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom + NestSpace.xxl,
      ),
      children: [
        Text(item.name, style: nest.text.title),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: NestSpace.sm,
          children: [
            Text(
              quantity == null || quantity.isEmpty
                  ? where
                  : '$quantity · $where',
              style: nest.text.caption.copyWith(
                color: nest.colors.inkSecondary,
              ),
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
        ),
        const SizedBox(height: NestSpace.sm),
        if (controller.outcome == ListMatchOutcome.removed)
          ProductsMessage(
            title: ListMatchCopy.removedTitle,
            message: ListMatchCopy.removedBody(item.name),
          )
        else
          switch (controller.products) {
            AsyncLoading() => Semantics(
              label: CheckersCopy.matchesLoading(controller.shop),
              child: _ProductGrid(
                count: 4,
                builder: (_, _) => const NestSkeleton(height: skeletonHeight),
              ),
            ),
            AsyncFailure(:final failure) => ProductsMessage(
              message: AppCopy.failure(failure),
              actionLabel: CheckersCopy.retry,
              onAction: controller.retry,
            ),
            AsyncData(value: final products) when products.isEmpty =>
              ProductsMessage(
                title: CheckersCopy.matchesEmptyTitle(controller.shop),
                message: ListMatchCopy.emptyBody(controller.shop),
              ),
            AsyncData(value: final products) => _ProductGrid(
              count: products.length,
              builder: (index, side) => _ProductTile(
                key: ValueKey('list-match-${products[index].id}'),
                product: products[index],
                pictureSize: side - NestSpace.sm * 2,
                isSelected: products[index] == controller.selected,
                isBestMatch: products[index].id == controller.bestMatchId,
                onTap: () => controller.select(products[index]),
              ),
            ),
          },
      ],
    );
  }
}

/// Rows of tiles as tall as their tallest, so a row's cards end together
/// whatever their words run to.
class _ProductGrid extends StatelessWidget {
  const _ProductGrid({required this.count, required this.builder});

  final int count;
  final Widget Function(int index, double side) builder;

  @override
  Widget build(BuildContext context) {
    final grow = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.6);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = (width / (ListMatchStep.tileWidth * grow))
            .floor()
            .clamp(2, 4);
        final side = (width - NestSpace.sm * (columns - 1)) / columns;
        return Column(
          children: [
            for (var start = 0; start < count; start += columns) ...[
              if (start > 0) const SizedBox(height: NestSpace.sm),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var each = start; each < start + columns; each++) ...[
                      if (each > start) const SizedBox(width: NestSpace.sm),
                      SizedBox(
                        width: side,
                        child: each < count
                            ? builder(each, side)
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.product,
    required this.pictureSize,
    required this.isSelected,
    required this.isBestMatch,
    required this.onTap,
    super.key,
  });

  final RetailerProduct product;
  final double pictureSize;
  final bool isSelected;
  final bool isBestMatch;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final price = CheckersCopy.price(
      product.price,
      perKilogram: product.isSoldByWeight,
    );
    final oldPrice = product.oldPrice;
    // A tag keeps to one line, and at large text a tile is too narrow for
    // its words, so there they are set as text that wraps.
    final isLargeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    Widget fact(String label, NestTagTone tone) => isLargeText
        ? Text(label, textAlign: TextAlign.center, style: nest.text.label)
        : NestTag(label: label, tone: tone);
    return NestPickTile(
      picture: RetailerProductImage(
        retailer: product.retailer,
        imageId: product.imageId,
        size: pictureSize,
      ),
      label: product.name,
      semanticLabel: ListMatchCopy.product(
        product.name,
        price,
        isSelected: isSelected,
        isBestMatch: isBestMatch,
        isInStock: product.isInStock,
      ),
      isSelected: isSelected,
      onTap: onTap,
      footer: ExcludeSemantics(
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: NestSpace.sm,
          runSpacing: NestSpace.xs,
          children: [
            Text(price, style: nest.text.bodyStrong),
            if (oldPrice != null)
              Text(
                CheckersCopy.was(oldPrice),
                style: nest.text.caption.copyWith(
                  color: nest.colors.inkTertiary,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            if (isBestMatch)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isLargeText) ...[
                    const NestTwig(
                      pose: NestTwigPose.waving,
                      size: NestSize.twigSmall,
                      semanticsLabel: AiCopy.twigBestMatch,
                    ),
                    const SizedBox(width: NestSpace.xs),
                  ],
                  Flexible(
                    child: fact(CheckersCopy.bestMatch, NestTagTone.success),
                  ),
                ],
              ),
            if (product.isOnPromotion)
              fact(CheckersCopy.deal, NestTagTone.accent),
            if (!product.isInStock)
              fact(CheckersCopy.outOfStock, NestTagTone.warning),
          ],
        ),
      ),
    );
  }
}
