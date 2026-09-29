import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/lunch_cheaper_swaps.dart';
import 'art/lunch_glyph.dart';

/// One cheaper swap: what for what, how much it saves over how many boxes,
/// why it is fair to the child — and the button that makes it (lunch-box
/// ADR-0007).
class LunchSwapRow extends StatelessWidget {
  const LunchSwapRow({required this.swap, required this.onSwap, super.key});

  final LunchCheaperSwap swap;

  /// Null for somebody who may only look.
  final VoidCallback? onSwap;

  @override
  Widget build(BuildContext context) {
    final onSwap = this.onSwap;
    return NestListRow(
      title: LunchBudgetCopy.swapLine(swap.from.name, swap.to.item.name),
      subtitle: [
        LunchBudgetCopy.swapSaves(
          swap.saving.money.display,
          swap.weekdays.length,
        ),
        LunchBudgetCopy.swapWhy,
      ].join(' · '),
      leading: LunchSlotTile(slot: swap.slot),
      // Under the words, not beside them: at large text a button beside a
      // sentence leaves the sentence no room.
      footer: onSwap == null
          ? null
          : Align(
              alignment: AlignmentDirectional.centerStart,
              child: NestButton(
                label: LunchBudgetCopy.swap,
                icon: Icons.swap_horiz_rounded,
                variant: NestButtonVariant.tonal,
                size: NestButtonSize.small,
                isExpanded: false,
                onPressed: onSwap,
              ),
            ),
    );
  }
}
