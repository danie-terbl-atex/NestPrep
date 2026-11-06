import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../add_to_checkers/ui/product_suggestion_row.dart';
import '../../add_to_checkers/ui/retailer_product_image.dart';
import '../model/checked_product.dart';
import '../model/idea_search.dart';
import '../model/shop_week.dart';

/// What a parent chose for one compartment — on that day, or on [everyDay]
/// the plan holds it (lunch-box ADR-0028 §6).
sealed class SwapChoice {
  const SwapChoice({required this.everyDay});

  final bool everyDay;
}

final class SwapToProduct extends SwapChoice {
  const SwapToProduct({
    required this.ideaId,
    required this.productId,
    required super.everyDay,
  });

  final String ideaId;
  final String productId;
}

final class SwapToEmpty extends SwapChoice {
  const SwapToEmpty({required super.everyDay});
}

/// Every product kept for the child [childId] in this compartment's ideas,
/// with the shop's picture of it, its idea, its pack price, about how many lunches a pack does and what
/// a lunch costs — and a caution on one nothing is known to be in, offered to
/// a child with an allergy — and *Leave it empty* — nothing else is offered, so a swap can never
/// reach for something NestPrep left out (lunch-box ADR-0012 §2). *Every day
/// this week* starts at [everyDay].
Future<SwapChoice?> showPlanWeekSwapSheet({
  required BuildContext context,
  required String title,
  required String childId,
  required List<(IdeaSearch, CheckedProduct)> options,
  required ShopPick? current,
  required int Function(String productId) boxesPerPackOf,
  required bool everyDay,
}) {
  var isEveryDay = everyDay;
  return showNestSheet<SwapChoice>(
    context: context,
    title: title,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setState) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          NestCheckRow(
            key: const ValueKey('swap-every-day'),
            label: PlanWeekCopy.swapEveryDay,
            value: isEveryDay,
            onChanged: (value) => setState(() => isEveryDay = value),
          ),
          const SizedBox(height: NestSpace.sm),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final (search, product) in options)
                  NestListRow(
                    key: ValueKey('swap-${search.ideaId}-${product.productId}'),
                    leading: RetailerProductImage(
                      retailer: product.product.retailer,
                      imageId: product.product.imageId,
                      size: ProductSuggestionRow.imageSize,
                    ),
                    title: product.product.name,
                    subtitle: PlanWeekCopy.swapOption(
                      idea: search.idea.idea,
                      price: product.product.price,
                      boxesPerPack: boxesPerPackOf(product.productId),
                    ),
                    footer: product.needsLabelCheckFor(childId)
                        ? NestToneRow(
                            icon: LucideIcons.triangleAlert,
                            tone: NestTagTone.warning,
                            title: PlanWeekCopy.labelCheck(
                              product.product.retailer,
                            ),
                          )
                        : null,
                    isSelected:
                        current?.productId == product.productId &&
                        current?.ideaId == search.ideaId,
                    onTap: () => Navigator.of(sheetContext).pop(
                      SwapToProduct(
                        ideaId: search.ideaId,
                        productId: product.productId,
                        everyDay: isEveryDay,
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
            onPressed: () =>
                Navigator.of(sheetContext)
                    .pop(SwapToEmpty(everyDay: isEveryDay)),
          ),
        ],
      ),
    ),
  );
}
