import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/ai_copy.dart';
import '../../../shared/copy/checkers_copy.dart';
import '../model/retailer_product.dart';
import 'retailer_product_image.dart';

/// One Checkers product under a grocery item: picture, name, brand, price,
/// and whether it is on a deal or out of stock — in words, never by colour
/// alone (`FE-13`). Tapping *Pick* reports it; the panel decides the rest.
class CheckersProductTile extends StatelessWidget {
  const CheckersProductTile({
    required this.product,
    required this.onPick,
    this.isBestMatch = false,
    super.key,
  });

  final RetailerProduct product;
  final bool isBestMatch;

  /// Null while a pick is being saved.
  final VoidCallback? onPick;

  static const imageSize = 56.0;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final oldPrice = product.oldPrice;
    final brand = product.brand;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RetailerProductImage(
          retailer: product.retailer,
          imageId: product.imageId,
          size: imageSize,
        ),
        const SizedBox(width: NestSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(product.name, style: nest.text.bodyStrong),
              if (brand != null)
                Text(
                  brand,
                  style: nest.text.caption.copyWith(
                    color: nest.colors.inkSecondary,
                  ),
                ),
              const SizedBox(height: NestSpace.xs),
              Wrap(
                spacing: NestSpace.sm,
                runSpacing: NestSpace.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Jev ranked it, so Twig stands beside the words
                  // (design-system ADR-0012); the two wrap as one.
                  if (isBestMatch)
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        NestTwig(
                          pose: NestTwigPose.waving,
                          size: NestSize.twigSmall,
                          semanticsLabel: AiCopy.twigBestMatch,
                        ),
                        SizedBox(width: NestSpace.xs),
                        Flexible(
                          child: NestTag(
                            label: CheckersCopy.bestMatch,
                            tone: NestTagTone.success,
                          ),
                        ),
                      ],
                    ),
                  Text(
                    CheckersCopy.price(
                      product.price,
                      perKilogram: product.isSoldByWeight,
                    ),
                    style: nest.text.label,
                  ),
                  if (oldPrice != null)
                    Text(
                      CheckersCopy.was(oldPrice),
                      style: nest.text.caption.copyWith(
                        color: nest.colors.inkTertiary,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  if (product.isOnPromotion)
                    const NestTag(
                      label: CheckersCopy.deal,
                      tone: NestTagTone.accent,
                    ),
                  if (!product.isInStock)
                    const NestTag(
                      label: CheckersCopy.outOfStock,
                      tone: NestTagTone.warning,
                    ),
                ],
              ),
              const SizedBox(height: NestSpace.xs),
              // Under the words rather than beside them, so at 200% text the
              // name keeps the width it needs (`FE-14`).
              NestButton(
                label: CheckersCopy.pick,
                variant: NestButtonVariant.tonal,
                size: NestButtonSize.small,
                isExpanded: false,
                onPressed: onPick,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
