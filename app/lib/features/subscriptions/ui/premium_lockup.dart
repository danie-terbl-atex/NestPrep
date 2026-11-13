import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/subscription_copy.dart';
import '../state/household_entitlement.dart';

/// The brand at the head of the household's home, with Premium's seal beside
/// it while the household has Premium (subscriptions ADR-0007).
class PremiumLockup extends StatelessWidget {
  const PremiumLockup({super.key});

  @override
  Widget build(BuildContext context) {
    final isPremium = context.watch<HouseholdEntitlement>().isPremium;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const NestBrandLockup(semanticsLabel: AppCopy.appName),
        if (isPremium) ...[
          const SizedBox(width: NestSpace.md),
          const NestPremiumSeal(label: SubscriptionCopy.premium),
        ],
      ],
    );
  }
}
