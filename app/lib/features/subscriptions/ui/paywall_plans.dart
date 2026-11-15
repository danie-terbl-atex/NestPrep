import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/subscription_copy.dart';
import '../model/plan_choice.dart';
import '../model/subscription_plan.dart';
import 'plan_option_card.dart';

/// The plans in the store's own prices, the suggested one tagged, and the
/// yearly saving said as a proportion — never a price NestPrep worked out
/// (`ENG-20`). Side by side in the paywall's dock, stacked where the text
/// is too large for two to a row.
class PaywallPlans extends StatelessWidget {
  const PaywallPlans({
    required this.choice,
    required this.selected,
    required this.onSelect,
    required this.isSideBySide,
    super.key,
  });

  final PlanChoice choice;
  final SubscriptionPlan? selected;

  /// Null while a purchase is under way.
  final ValueChanged<SubscriptionPlan>? onSelect;
  final bool isSideBySide;

  @override
  Widget build(BuildContext context) {
    final saving = choice.yearlySavingPercent;
    final select = onSelect;
    final cards = [
      for (final product in choice.products)
        PlanOptionCard(
          key: ValueKey(product.plan),
          product: product,
          isSelected: product.plan == selected,
          isCompact: isSideBySide,
          onSelect: select == null ? null : () => select(product.plan),
          tag: switch (product.plan) {
            SubscriptionPlan.yearly when saving != null =>
              SubscriptionCopy.saving(saving),
            _ when product.plan == choice.featured =>
              SubscriptionCopy.suggested,
            _ => null,
          },
        ),
    ];
    if (isSideBySide) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (at, card) in cards.indexed) ...[
              if (at > 0) const SizedBox(width: NestSpace.md),
              Expanded(child: card),
            ],
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const NestSectionHeader(title: SubscriptionCopy.choosePlan),
        const SizedBox(height: NestSpace.sm),
        for (final card in cards) ...[
          card,
          const SizedBox(height: NestSpace.sm),
        ],
      ],
    );
  }
}
