import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/list_match_copy.dart';
import '../state/list_match_controller.dart';

/// What the run came to, once every item has had its turn.
class ListMatchSummary extends StatelessWidget {
  const ListMatchSummary({super.key});

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final controller = context.watch<ListMatchController>();
    final estimate = controller.estimate;
    final skipped = controller.skippedCount;
    final removed = controller.removedCount;
    final note = nest.text.bodySecondary;
    return ListView(
      padding: EdgeInsets.only(
        top: NestSpace.xxl,
        bottom: MediaQuery.paddingOf(context).bottom + NestSpace.xxl,
      ),
      children: [
        Semantics(
          liveRegion: true,
          child: Column(
            children: [
              const NestIconTile(
                icon: LucideIcons.shoppingBasket,
                tint: NestTileTint.basil,
              ),
              const SizedBox(height: NestSpace.lg),
              Text(
                ListMatchCopy.summaryFigure(
                  controller.pickedCount,
                  controller.items.length,
                ),
                textAlign: TextAlign.center,
                style: nest.text.figure,
              ),
              Text(
                ListMatchCopy.summaryMatched(controller.shop),
                textAlign: TextAlign.center,
                style: nest.text.title,
              ),
            ],
          ),
        ),
        const SizedBox(height: NestSpace.lg),
        if (estimate != null)
          Text(
            ListMatchCopy.estimate(estimate),
            textAlign: TextAlign.center,
            style: note,
          ),
        if (skipped > 0)
          Text(
            ListMatchCopy.skipped(skipped),
            textAlign: TextAlign.center,
            style: note,
          ),
        if (removed > 0)
          Text(
            ListMatchCopy.removed(removed),
            textAlign: TextAlign.center,
            style: note,
          ),
      ],
    );
  }
}

class ListMatchSummaryActions extends StatelessWidget {
  const ListMatchSummaryActions({super.key});

  static const cartKey = ValueKey('list-match-cart');
  static const doneKey = ValueKey('list-match-done');

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ListMatchController>();
    final hasPicks = controller.pickedCount > 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasPicks) ...[
          NestButton(
            key: cartKey,
            label: ListMatchCopy.toCart(controller.shop),
            icon: LucideIcons.shoppingBasket,
            onPressed: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: NestSpace.sm),
        ],
        NestButton(
          key: doneKey,
          label: ListMatchCopy.backToList,
          variant: hasPicks
              ? NestButtonVariant.ghost
              : NestButtonVariant.primary,
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }
}
