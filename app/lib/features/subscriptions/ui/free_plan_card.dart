import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/subscription_copy.dart';

/// What the free plan already gives — said first, so premium reads as more
/// rather than as what was being held back — and the way to premium.
class FreePlanCard extends StatelessWidget {
  const FreePlanCard({required this.onUpgrade, super.key});

  final VoidCallback onUpgrade;

  static const _included = [
    (Icons.calendar_today_outlined, SubscriptionCopy.freeCalendar),
    (Icons.shopping_basket_outlined, SubscriptionCopy.freeLists),
    (Icons.child_care_outlined, SubscriptionCopy.freeOneChild),
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
            icon: Icons.workspace_premium_outlined,
            onPressed: onUpgrade,
          ),
        ],
      ),
    );
  }
}
