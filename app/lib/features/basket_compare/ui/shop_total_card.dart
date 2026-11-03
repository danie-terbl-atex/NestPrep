import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/basket_compare_copy.dart';
import '../../../shared/copy/checkers_copy.dart';
import '../../../shared/money/money.dart';
import '../../add_to_checkers/ui/retailer_logo.dart';
import '../model/basket_comparison.dart';

/// One shop's basket: what everything it has costs, how many items it has,
/// how many it lacks, and — when the shops differ in what they have — the
/// like-for-like figure the verdict is judged on.
class ShopTotalCard extends StatelessWidget {
  const ShopTotalCard({
    required this.total,
    required this.itemCount,
    required this.shopCount,
    required this.isCheapest,
    required this.showsLikeForLike,
    super.key,
  });

  final ShopTotal total;

  /// The items settled so far, which [ShopTotal.found] is out of.
  final int itemCount;
  final int shopCount;
  final bool isCheapest;
  final bool showsLikeForLike;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final secondary = nest.text.caption.copyWith(
      color: nest.colors.inkSecondary,
    );
    return NestCard(
      variant: NestCardVariant.flat,
      padding: const EdgeInsets.all(NestSpace.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RetailerLogo.decorative(
            retailer: total.shop,
            size: NestSize.logoMedium,
          ),
          const SizedBox(width: NestSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: NestSpace.sm,
                  runSpacing: NestSpace.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      CheckersCopy.retailerName(total.shop),
                      style: nest.text.bodyStrong,
                    ),
                    if (isCheapest)
                      const NestTag(
                        label: BasketCompareCopy.cheapestTag,
                        tone: NestTagTone.success,
                        icon: LucideIcons.badgeCheck,
                      ),
                  ],
                ),
                Text(total.total.display, style: nest.text.figureSmall),
                const SizedBox(height: NestSpace.xs),
                Wrap(
                  spacing: NestSpace.sm,
                  runSpacing: NestSpace.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      BasketCompareCopy.foundOf(total.found, itemCount),
                      style: secondary,
                    ),
                    if (total.missing > 0)
                      NestTag(
                        label: BasketCompareCopy.notAvailable(total.missing),
                        tone: NestTagTone.warning,
                        icon: LucideIcons.packageX,
                      ),
                  ],
                ),
                if (showsLikeForLike) ...[
                  const SizedBox(height: NestSpace.xs),
                  Text(
                    BasketCompareCopy.likeForLike(total.likeForLike, shopCount),
                    style: secondary,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The cheapest split, as a figure only: NestPrep fills one shop's cart at a
/// time (basket-compare ADR-0001 §4).
class SplitHint extends StatelessWidget {
  const SplitHint({required this.total, required this.less, super.key});

  final Money total;
  final Money less;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          LucideIcons.split,
          size: NestSize.iconSmall,
          color: nest.colors.secondaryInk,
        ),
        const SizedBox(width: NestSpace.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                BasketCompareCopy.split(total, less),
                style: nest.text.label.copyWith(
                  color: nest.colors.secondaryInk,
                ),
              ),
              Text(
                BasketCompareCopy.splitNote,
                style: nest.text.caption.copyWith(
                  color: nest.colors.inkSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
