import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/checked_product.dart';
import '../model/idea_search.dart';
import '../model/shop_week.dart';

/// What a parent chose for one compartment.
sealed class SwapChoice {
  const SwapChoice();
}

final class SwapToProduct extends SwapChoice {
  const SwapToProduct({required this.ideaId, required this.productId});

  final String ideaId;
  final String productId;
}

final class SwapToEmpty extends SwapChoice {
  const SwapToEmpty();
}

/// Every product kept for this child in this compartment's ideas, with its
/// idea and price, and *Leave it empty* — nothing else is offered, so a swap
/// can never reach for something NestPrep left out (lunch-box ADR-0012 §2).
Future<SwapChoice?> showPlanWeekSwapSheet({
  required BuildContext context,
  required String title,
  required List<(IdeaSearch, CheckedProduct)> options,
  required ShopPick? current,
}) => showNestSheet<SwapChoice>(
  context: context,
  title: title,
  builder: (sheetContext) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      Flexible(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final (search, product) in options)
              NestListRow(
                key: ValueKey('swap-${search.ideaId}-${product.productId}'),
                title: product.product.name,
                subtitle:
                    '${search.idea.idea} · ${product.product.price.display}',
                isSelected:
                    current?.productId == product.productId &&
                    current?.ideaId == search.ideaId,
                onTap: () => Navigator.of(sheetContext).pop(
                  SwapToProduct(
                    ideaId: search.ideaId,
                    productId: product.productId,
                  ),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: NestSpace.md),
      NestButton(
        label: PlanWeekCopy.leaveEmpty,
        variant: NestButtonVariant.outline,
        onPressed: () => Navigator.of(sheetContext).pop(const SwapToEmpty()),
      ),
    ],
  ),
);
