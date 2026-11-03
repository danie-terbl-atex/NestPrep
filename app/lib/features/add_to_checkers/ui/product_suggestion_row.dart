import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/ai_copy.dart';
import '../../../shared/copy/checkers_copy.dart';
import '../model/retailer_product.dart';
import 'retailer_product_image.dart';

/// One product offered while a grocery name is typed (add-to-checkers
/// ADR-0007): the whole row is the tap that adds it, so it stays one line
/// of picture, name and price — the list under it stays in sight. Jev's
/// best, a deal and out of stock are said in words under it (`FE-13`).
class ProductSuggestionRow extends StatelessWidget {
  const ProductSuggestionRow({
    required this.product,
    required this.onAdd,
    this.isBestMatch = false,
    super.key,
  });

  final RetailerProduct product;
  final bool isBestMatch;

  /// Null while a pick is being added.
  final VoidCallback? onAdd;

  static const imageSize = 48.0;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final brand = product.brand;
    final price = CheckersCopy.price(
      product.price,
      perKilogram: product.isSoldByWeight,
    );
    final hasTags = isBestMatch || product.isOnPromotion || !product.isInStock;
    return NestListRow(
      leading: RetailerProductImage(
        retailer: product.retailer,
        imageId: product.imageId,
        size: imageSize,
      ),
      title: product.name,
      subtitle: brand == null ? price : '$price · $brand',
      footer: hasTags
          ? Wrap(
              spacing: NestSpace.sm,
              runSpacing: NestSpace.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
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
            )
          : null,
      trailing: Icon(
        LucideIcons.plus,
        color: onAdd == null ? nest.colors.inkTertiary : nest.colors.ink,
        semanticLabel: CheckersCopy.addProduct,
      ),
      onTap: onAdd,
    );
  }
}
