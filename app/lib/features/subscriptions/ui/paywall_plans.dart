import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/subscription_copy.dart';
import '../model/plan_choice.dart';
import '../model/subscription_plan.dart';
import 'plan_option_card.dart';

/// The two plans side by side in the store's own prices, the suggested one
/// tagged, and the yearly saving said as a proportion — never a price
/// NestPrep worked out (`ENG-20`).
class PaywallPlans extends StatelessWidget {
  const PaywallPlans({
    required this.choice,
    required this.selected,
    required this.onSelect,
    super.key,
  });

  final PlanChoice choice;
  final SubscriptionPlan? selected;

  /// Null while a purchase is under way.
  final ValueChanged<SubscriptionPlan>? onSelect;

  @override
  Widget build(BuildContext context) {
    final saving = choice.yearlySavingPercent;
    final select = onSelect;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const NestSectionHeader(title: SubscriptionCopy.choosePlan),
        const SizedBox(height: NestSpace.sm),
        for (final product in choice.products) ...[
          PlanOptionCard(
            key: ValueKey(product.plan),
            product: product,
            isSelected: product.plan == selected,
            onSelect: select == null ? null : () => select(product.plan),
            tag: switch (product.plan) {
              SubscriptionPlan.yearly when saving != null =>
                SubscriptionCopy.saving(saving),
              _ when product.plan == choice.featured =>
                SubscriptionCopy.suggested,
              _ => null,
            },
          ),
          const SizedBox(height: NestSpace.sm),
        ],
      ],
    );
  }
}
