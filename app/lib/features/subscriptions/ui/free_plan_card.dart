import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/subscription_copy.dart';

/// What the free plan already gives — said first, so premium reads as more
/// rather than as what was being held back — and the way to premium.
class FreePlanCard extends StatelessWidget {
  const FreePlanCard({required this.onUpgrade, super.key});

  final VoidCallback onUpgrade;

  static const _included = [
    (LucideIcons.calendar, SubscriptionCopy.freeCalendar),
    (LucideIcons.shoppingBasket, SubscriptionCopy.freeLists),
    (LucideIcons.baby, SubscriptionCopy.freeOneChild),
  ];

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return NestCard(
      variant: NestCardVariant.tinted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(SubscriptionCopy.whatYouHave, style: nest.text.title),
          const SizedBox(height: NestSpace.md),
          for (final (icon, label) in _included)
            Padding(
              padding: const EdgeInsets.only(bottom: NestSpace.sm),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: NestSize.iconMedium,
                    color: nest.colors.accentInk,
                  ),
                  const SizedBox(width: NestSpace.md),
                  Expanded(child: Text(label, style: nest.text.body)),
                ],
              ),
            ),
          const SizedBox(height: NestSpace.md),
          NestButton(
            label: SubscriptionCopy.upgrade,
            icon: LucideIcons.award,
            onPressed: onUpgrade,
          ),
        ],
      ),
    );
  }
}
