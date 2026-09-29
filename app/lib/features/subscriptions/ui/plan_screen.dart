import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/subscription_copy.dart';
import '../../../shared/ui/back_leading.dart';
import '../model/entitlement.dart';
import '../state/household_entitlement.dart';
import '../state/plan_controller.dart';
import 'plan_body.dart';

/// Plan and billing (subscriptions ADR-0001): which plan the household is
/// on, when it renews or ends, who bought it, and the ways to upgrade,
/// restore and manage. The plan itself is the household's entitlement
/// listener, read once for everything under the shell; this screen adds only
/// its actions. All four states come from the kit (`FE-08`).
class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final household = context.watch<HouseholdEntitlement>();
    final controller = context.watch<PlanController>();
    final failure = controller.actionFailure;
    return NestScaffold(
      title: SubscriptionCopy.planTitle,
      leading: backLeading(context),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (failure != null)
            Padding(
              padding: const EdgeInsets.only(bottom: NestSpace.lg),
              child: NestBanner(
                message: AppCopy.failure(failure),
                tone: NestBannerTone.danger,
                actionLabel: AppCopy.back,
                onAction: controller.dismissActionFailure,
              ),
            ),
          Expanded(
            child: NestAsyncView<Entitlement>(
              state: household.entitlement,
              // A household that has never bought has a plan too: free.
              isEmpty: (_) => false,
              onRetry: household.retry,
              emptyBuilder: (_) => const SizedBox.shrink(),
              dataBuilder: (_, entitlement) => PlanBody(
                entitlement: entitlement,
                isPremium: household.isPremium,
                controller: controller,
                now: household.now(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
