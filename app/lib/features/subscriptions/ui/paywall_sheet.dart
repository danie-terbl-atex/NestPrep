import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/subscription_copy.dart';
import '../../household/model/household_view.dart';
import '../data/store_billing.dart';
import '../data/subscription_directory.dart';
import '../model/premium_feature.dart';
import '../model/purchase_progress.dart';
import '../state/paywall_controller.dart';
import '../state/purchase_coordinator.dart';
import 'paywall_offer_view.dart';
import 'premium_benefits.dart';
import 'premium_mark.dart';

/// Offers premium, opened on the [feature] the person reached for — a second
/// child, the lunch learning loop, the prep list — or from the plan screen
/// (subscriptions ADR-0001). Answers true once the household has premium.
///
/// Reads what it needs from the caller's context before the sheet opens, so
/// it works from any screen under the household shell.
Future<bool> showPaywall(
  BuildContext context, {
  required PremiumFeature feature,
}) async {
  final householdId = context.read<HouseholdView>().household.id;
  final directory = context.read<SubscriptionDirectory>();
  final billing = context.read<StoreBilling>();
  final coordinator = context.read<PurchaseCoordinator>();
  final upgraded = await showNestSheet<bool>(
    context: context,
    builder: (_) => ChangeNotifierProvider(
      create: (_) => PaywallController(
        subscriptionDirectory: directory,
        storeBilling: billing,
        purchaseCoordinator: coordinator,
        householdId: householdId,
        feature: feature,
      ),
      child: const PaywallSheet(),
    ),
  );
  return upgraded ?? false;
}

class PaywallSheet extends StatelessWidget {
  const PaywallSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PaywallController>();
    final nest = NestTheme.of(context);
    if (controller.progress is PurchaseSucceeded) {
      return _Welcome(
        onDone: () {
          controller.acknowledge();
          Navigator.of(context).pop(true);
        },
      );
    }
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const NestRiseIn(child: Center(child: PremiumMark())),
          const SizedBox(height: NestSpace.md),
          NestRiseIn(
            index: 1,
            child: Column(
              children: [
                const NestTag(
                  label: SubscriptionCopy.paywallLabel,
                  tone: NestTagTone.accent,
                  icon: Icons.auto_awesome,
                ),
                const SizedBox(height: NestSpace.sm),
                Text(
                  SubscriptionCopy.headline(controller.feature),
                  style: nest.text.headline,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: NestSpace.sm),
                Text(
                  SubscriptionCopy.pitch(controller.feature),
                  style: nest.text.bodySecondary,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: NestSpace.lg),
          const NestRiseIn(index: 2, child: PremiumBenefits()),
          const SizedBox(height: NestSpace.lg),
          NestRiseIn(index: 3, child: PaywallOfferView(controller: controller)),
        ],
      ),
    );
  }
}

/// The moment it worked: said once, warmly, with one way on.
class _Welcome extends StatelessWidget {
  const _Welcome({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return SingleChildScrollView(
      child: Column(
        children: [
          const NestRiseIn(child: PremiumMark()),
          const SizedBox(height: NestSpace.lg),
          Text(
            SubscriptionCopy.welcomeTitle,
            style: nest.text.headline,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: NestSpace.sm),
          Text(
            SubscriptionCopy.welcomeBody,
            style: nest.text.bodySecondary,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: NestSpace.xxl),
          NestButton(label: SubscriptionCopy.done, onPressed: onDone),
        ],
      ),
    );
  }
}
