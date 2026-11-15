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
    this.isCompact = false,
    super.key,
  });

  final StoreProduct product;
  final bool isSelected;

  /// Null while a purchase is under way: the choice is fixed.
  final VoidCallback? onSelect;

  /// "Save 17%", "Suggested" — or nothing.
  final String? tag;

  /// One of two side by side: the price under the name, not beside it.
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
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
        padding: EdgeInsets.all(isCompact ? NestSpace.md : NestSpace.lg),
        onTap: onSelect,
        child: isCompact
            ? _CompactPlan(product: product, isSelected: isSelected, tag: label)
            : _WidePlan(product: product, isSelected: isSelected, tag: label),
      ),
    );
  }
}

class _PlanRadio extends StatelessWidget {
  const _PlanRadio({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final colors = NestTheme.of(context).colors;
    return Icon(
      isSelected ? LucideIcons.circleDot : LucideIcons.circle,
      color: isSelected ? colors.accent : colors.inkTertiary,
      size: NestSize.iconMedium,
    );
  }
}

class _CompactPlan extends StatelessWidget {
  const _CompactPlan({
    required this.product,
    required this.isSelected,
    required this.tag,
  });

  final StoreProduct product;
  final bool isSelected;
  final String? tag;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final label = tag;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                SubscriptionCopy.planName(product.plan),
                style: nest.text.bodyStrong,
              ),
            ),
            _PlanRadio(isSelected: isSelected),
          ],
        ),
        const SizedBox(height: NestSpace.xxs),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(product.displayPrice, style: nest.text.title),
              const SizedBox(width: NestSpace.xs),
              Text(
                SubscriptionCopy.perPeriod(product.plan),
                style: nest.text.caption,
              ),
            ],
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: NestSpace.xs),
          NestTag(label: label, tone: NestTagTone.accent),
        ],
      ],
    );
  }
}

class _WidePlan extends StatelessWidget {
  const _WidePlan({
    required this.product,
    required this.isSelected,
    required this.tag,
  });

  final StoreProduct product;
  final bool isSelected;
  final String? tag;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final label = tag;
    return Row(
      children: [
        _PlanRadio(isSelected: isSelected),
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
    );
  }
}
