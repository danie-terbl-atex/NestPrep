import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../groceries/model/grocery_item.dart';
import '../state/product_match_controller.dart';
import 'product_match_line.dart';
import 'product_match_panel.dart';

/// What Checkers adds under one grocery item: the picked product and, when
/// this item is the one being matched, the panel of products itself.
///
/// Selects only whether this item is the target, so the rest of the list does
/// not rebuild while one item's matches load (`FE-12`).
class CheckersItemFooter extends StatelessWidget {
  const CheckersItemFooter({
    required this.item,
    required this.canEdit,
    super.key,
  });

  final GroceryItem item;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    final isTarget = context.select<ProductMatchController, bool>(
      (controller) => controller.target?.itemId == item.id,
    );
    final match = item.productMatch;
    if (match == null && !isTarget) return const SizedBox.shrink();
    final controller = context.read<ProductMatchController>();
    final canChange = canEdit && !item.isBought;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (match != null)
          ProductMatchLine(
            match: match,
            onChange: canChange ? () => controller.lookFor(item) : null,
            onClear: canChange ? () => controller.clear(item) : null,
          ),
        if (isTarget) ...[
          const SizedBox(height: NestSpace.sm),
          const ProductMatchPanel(),
        ],
      ],
    );
  }
}
