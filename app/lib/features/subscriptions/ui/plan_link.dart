import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/subscription_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/subscription_copy.dart';
import '../state/household_entitlement.dart';

/// The way to plan and billing, from the household screen — with which plan
/// the household is on said before it is tapped.
class PlanLink extends StatelessWidget {
  const PlanLink({required this.householdId, super.key});

  final String householdId;

  @override
  Widget build(BuildContext context) {
    final isPremium = context.watch<HouseholdEntitlement>().isPremium;
    return NestCard(
      variant: NestCardVariant.flat,
      padding: EdgeInsets.zero,
      child: NestListRow(
        title: SubscriptionCopy.openFromHousehold,
        subtitle: SubscriptionCopy.openFromHouseholdBody(isPremium: isPremium),
        leading: const NestIconTile(
          icon: Icons.workspace_premium_outlined,
          tint: NestTileTint.butter,
        ),
        trailing: const Icon(Icons.chevron_right),
        // Pushed, so back lands on the household screen (`FE-17`).
        onTap: () => context.push(SubscriptionRoute.pathFor(householdId)),
      ),
    );
  }
}
