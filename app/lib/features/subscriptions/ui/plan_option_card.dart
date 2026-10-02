import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/subscription_copy.dart';
import '../model/store_product.dart';

/// One plan to choose: its name, the store's own price for its period, and —
/// for the plan the offer suggests — a tag saying so, or how much a year
/// saves. One of a group of two, read by a screen reader as a choice with its
/// state (`FE-13`); the tint is never the only sign of which is chosen.
class PlanOptionCard extends StatelessWidget {
  const PlanOptionCard({
    required this.product,
    required this.isSelected,
    required this.onSelect,
    this.tag,
    super.key,
  });

  final StoreProduct product;
  final bool isSelected;

  /// Null while a purchase is under way: the choice is fixed.
  final VoidCallback? onSelect;

  /// "Save 17%", "Suggested" — or nothing.
  final String? tag;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final label = tag;
    return Semantics(
      container: true,
      button: true,
      inMutuallyExclusiveGroup: true,
      selected: isSelected,
      label: [
        SubscriptionCopy.planLabel(
          plan: product.plan,
          price: product.displayPrice,
        ),
        ?label,
      ].join(', '),
      excludeSemantics: true,
      child: NestCard(
        variant: isSelected ? NestCardVariant.tinted : NestCardVariant.flat,
        padding: const EdgeInsets.all(NestSpace.lg),
        onTap: onSelect,
        child: Row(
          children: [
            Icon(
              isSelected ? LucideIcons.circleDot : LucideIcons.circle,
              color: isSelected ? nest.colors.accent : nest.colors.inkTertiary,
              size: NestSize.iconMedium,
            ),
            const SizedBox(width: NestSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    SubscriptionCopy.planName(product.plan),
                    style: nest.text.bodyStrong,
                  ),
                  if (label != null) ...[
                    const SizedBox(height: NestSpace.xs),
                    NestTag(label: label, tone: NestTagTone.accent),
                  ],
                ],
              ),
            ),
            const SizedBox(width: NestSpace.md),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    product.displayPrice,
                    style: nest.text.title,
                    textAlign: TextAlign.end,
                  ),
                  Text(
                    SubscriptionCopy.perPeriod(product.plan),
                    style: nest.text.caption,
                    textAlign: TextAlign.end,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
