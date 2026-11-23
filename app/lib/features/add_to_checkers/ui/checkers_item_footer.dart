import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../groceries/model/grocery_item.dart';
import '../state/product_match_controller.dart';
import '../state/retailer_choice_controller.dart';
import 'product_match_line.dart';
import 'product_match_panel.dart';
import 'shops_lock.dart';
import 'shops_on_list.dart';

/// What a shop adds under one grocery item: the picked product and, when
/// this item is the one being matched, the panel of products itself.
///
/// Selects only whether this item is the target, so the rest of the list does
/// not rebuild while one item's matches load (`FE-12`).
class CheckersItemFooter extends StatelessWidget {
  const CheckersItemFooter({
    required this.item,
    required this.canEdit,
    this.productsKey,
    super.key,
  });

  final GroceryItem item;
  final bool canEdit;

  /// Marks the open products, so the list can measure them before they close.
  final Key? productsKey;

  @override
  Widget build(BuildContext context) {
    final isTarget = context.select<ProductMatchController, bool>(
      (controller) => controller.target?.itemId == item.id,
    );
    final match = shownMatchOf(context, item);
    if (match == null && !isTarget) return const SizedBox.shrink();
    final controller = context.read<ProductMatchController>();
    final canChange = canEdit && !item.isBought;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (match != null)
          ProductMatchLine(
            match: match,
            onChange: canChange ? () => _change(context, controller) : null,
            onClear: canChange ? () => controller.clear(item) : null,
          ),
        if (isTarget)
          Padding(
            key: productsKey,
            padding: const EdgeInsets.only(top: NestSpace.sm),
            child: const ProductMatchPanel(),
          ),
      ],
    );
  }

  Future<void> _change(
    BuildContext context,
    ProductMatchController controller,
  ) async {
    final shop = context.read<RetailerChoiceController>().chosen;
    if (!await ensureShops(context)) return;
    controller.lookFor(item, at: shop);
  }
}
