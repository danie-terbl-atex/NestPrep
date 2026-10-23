import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/checkers_copy.dart';
import '../../groceries/model/product_match.dart';
import 'retailer_logo.dart';
import 'retailer_product_image.dart';

/// The picked product, compact, under a grocery item, led by its shop's own
/// logo so a list matched at two shops reads at a glance (add-to-pnp
/// ADR-0007) — with *change* and *remove* for somebody who may edit the list.
class ProductMatchLine extends StatelessWidget {
  const ProductMatchLine({
    required this.match,
    this.onChange,
    this.onClear,
    super.key,
  });

  final ProductMatch match;
  final VoidCallback? onChange;
  final VoidCallback? onClear;

  static const imageSize = 32.0;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final change = onChange;
    final clear = onClear;
    return Row(
      children: [
        // The words beside it name the shop for a screen reader.
        RetailerLogo.decorative(retailer: match.retailer),
        const SizedBox(width: NestSpace.sm),
        RetailerProductImage(
          retailer: match.retailer,
          imageId: match.imageId,
          size: imageSize,
        ),
        const SizedBox(width: NestSpace.sm),
        Expanded(
          child: Semantics(
            label: CheckersCopy.matchedSemantics(match.retailer, match.name),
            excludeSemantics: true,
            child: Text(
              '${match.name} · ${CheckersCopy.price(match.price, perKilogram: match.isSoldByWeight)}',
              style: nest.text.caption.copyWith(
                color: nest.colors.inkSecondary,
              ),
            ),
          ),
        ),
        if (change != null)
          NestIconButton(
            icon: LucideIcons.arrowLeftRight,
            label: CheckersCopy.changeMatch,
            variant: NestIconButtonVariant.plain,
            onPressed: change,
          ),
        if (clear != null)
          NestIconButton(
            icon: LucideIcons.x,
            label: CheckersCopy.clearMatch,
            variant: NestIconButtonVariant.plain,
            onPressed: clear,
          ),
      ],
    );
  }
}
