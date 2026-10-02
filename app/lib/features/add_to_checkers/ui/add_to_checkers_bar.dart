import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/checkers_copy.dart';

/// Above the list when some unbought items have a Checkers product: how many,
/// and *Add to Checkers*. Absent otherwise — there is nothing to add.
class AddToCheckersBar extends StatelessWidget {
  const AddToCheckersBar({
    required this.matchedCount,
    required this.isPushing,
    required this.onAdd,
    super.key,
  });

  final int matchedCount;
  final bool isPushing;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return NestCard(
      variant: NestCardVariant.tinted,
      padding: const EdgeInsets.all(NestSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(CheckersCopy.readyToAdd(matchedCount), style: nest.text.label),
          const SizedBox(height: NestSpace.sm),
          NestButton(
            label: CheckersCopy.addToCheckers,
            icon: LucideIcons.shoppingCart,
            size: NestButtonSize.small,
            isExpanded: false,
            isLoading: isPushing,
            onPressed: isPushing ? null : onAdd,
          ),
        ],
      ),
    );
  }
}
