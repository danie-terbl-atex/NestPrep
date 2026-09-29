import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/subscription_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/time/household_clock.dart';
import '../../household/model/household_view.dart';
import '../model/entitlement.dart';
import '../model/premium_feature.dart';
import '../state/plan_controller.dart';
import 'free_plan_card.dart';
import 'paywall_sheet.dart';
import 'plan_actions.dart';
import 'plan_status_card.dart';
import 'premium_benefits.dart';

/// The plan screen once the entitlement has loaded: the plan and what is
/// worth knowing about it, what premium adds or the way to it, the
/// reassurance a lapsed household needs, and the buyer's way to their store.
class PlanBody extends StatelessWidget {
  const PlanBody({
    required this.entitlement,
    required this.isPremium,
    required this.controller,
    required this.now,
    super.key,
  });

  final Entitlement entitlement;
  final bool isPremium;
  final PlanController controller;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final view = context.read<HouseholdView>();
    final clock = context.read<HouseholdClock>();
    final until = entitlement.premiumUntil;
    final buyer = view.members
        .where((member) => member.id == entitlement.managedByMemberId)
        .firstOrNull;
    final buyerName = entitlement.managedByMemberId == null
        ? null
        : buyer?.displayName ?? SubscriptionCopy.someoneElse;
    final canManage = controller.canManage(entitlement);
    return ListView(
      children: [
        NestRiseIn(
          child: PlanStatusCard(
            entitlement: entitlement,
            isPremium: isPremium,
            untilLabel: until == null
                ? null
                : NestDates.full(clock.dateOf(until), clock.today),
            buyerName: buyerName,
          ),
        ),
        const SizedBox(height: NestSpace.lg),
        if (entitlement.hasLapsedAt(now)) ...[
          const NestBanner(
            message: SubscriptionCopy.keptSafe,
            tone: NestBannerTone.warning,
          ),
          const SizedBox(height: NestSpace.lg),
        ],
        if (isPremium) ...[
          const NestSectionHeader(title: SubscriptionCopy.whatPremiumAdds),
          const PremiumBenefits(),
        ] else if (view.permissions.isFamily)
          FreePlanCard(
            onUpgrade: () =>
                unawaited(showPaywall(context, feature: PremiumFeature.direct)),
          )
        else
          const NestBanner(message: SubscriptionCopy.askAParent),
        const SizedBox(height: NestSpace.xl),
        if (view.permissions.isFamily)
          PlanActions(
            progress: controller.progress,
            onManage: canManage ? controller.manage : null,
            onlyBuyerNote: !canManage && buyerName != null && isPremium
                ? SubscriptionCopy.onlyBuyerManages(buyerName)
                : null,
            onRestore: controller.restore,
            onDismiss: controller.acknowledge,
          ),
        const SizedBox(height: NestSpace.huge),
      ],
    );
  }
}
