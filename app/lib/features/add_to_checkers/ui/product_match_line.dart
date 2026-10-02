import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/checkers_copy.dart';
import '../../groceries/model/product_match.dart';
import 'checkers_product_image.dart';

/// The picked Checkers product, compact, under a grocery item — with *change*
/// and *remove* for somebody who may edit the list.
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
        CheckersProductImage(imageId: match.imageId, size: imageSize),
        const SizedBox(width: NestSpace.sm),
        Expanded(
          child: Semantics(
            label: CheckersCopy.matchedSemantics(match.name),
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
            icon: Icons.swap_horiz_rounded,
            label: CheckersCopy.changeMatch,
            variant: NestIconButtonVariant.plain,
            onPressed: change,
          ),
        if (clear != null)
          NestIconButton(
            icon: Icons.close_rounded,
            label: CheckersCopy.clearMatch,
            variant: NestIconButtonVariant.plain,
            onPressed: clear,
          ),
      ],
    );
  }
}
