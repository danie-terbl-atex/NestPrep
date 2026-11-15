import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/household_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/subscription_copy.dart';
import '../../../shared/flags/feature_flags_controller.dart';
import '../../accounts/ui/account_menu_button.dart';
import '../../assistants/ui/assistants_link.dart';
import '../../subscriptions/model/premium_feature.dart';
import '../../subscriptions/state/household_entitlement.dart';
import '../../subscriptions/ui/paywall_page.dart';
import '../model/household_place.dart';
import '../model/household_view.dart';

/// A household without Premium that holds more than the free plan's four
/// people — one whose Premium lapsed, or a fifth profile that slipped past
/// the rules' count — cannot carry on until it removes people or upgrades
/// (subscriptions ADR-0008). Every place is this screen instead, except the
/// ones [isOpenHere] names: managing the household, the plan, and where a
/// shop is unlinked and an assistant disconnected.
///
/// Decided from what both listeners last said, so it lifts by itself the
/// moment a person is removed or Premium starts, and never shows while the
/// entitlement is still unknown.
class HouseholdSizeLock extends StatelessWidget {
  const HouseholdSizeLock({
    required this.isOpenHere,
    required this.child,
    super.key,
  });

  final bool isOpenHere;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final view = context.watch<HouseholdView>();
    final entitlement = context.watch<HouseholdEntitlement>();
    final isLocked =
        !isOpenHere &&
        view.exceedsFreePlan &&
        entitlement.isKnown &&
        !entitlement.isPremium;
    return isLocked ? HouseholdOverLimitScreen(view: view) : child;
  }
}

class HouseholdOverLimitScreen extends StatelessWidget {
  const HouseholdOverLimitScreen({required this.view, super.key});

  final HouseholdView view;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final isFamily = view.permissions.isFamily;
    final canOpenAssistants = HouseholdPlace.assistants.isOpenTo(
      view,
      context.watch<FeatureFlagsController>().flags,
    );
    return NestScaffold(
      title: view.household.name,
      trailing: const [AccountMenuButton()],
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: NestSpace.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: NestIconTile(icon: LucideIcons.users)),
            const SizedBox(height: NestSpace.lg),
            Text(
              AccessCopy.overLimitTitle,
              style: nest.text.title,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: NestSpace.sm),
            Text(
              AccessCopy.overLimitBody(view.members.length),
              style: nest.text.bodySecondary,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: NestSpace.xl),
            if (!isFamily) ...[
              Text(
                AccessCopy.overLimitAskParent,
                style: nest.text.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: NestSpace.xl),
            ],
            NestButton(
              label: isFamily
                  ? AccessCopy.overLimitManage
                  : AccessCopy.overLimitSeeHousehold,
              icon: LucideIcons.users,
              onPressed: () => context.push(
                HouseholdRoute.householdPathFor(view.household.id),
              ),
            ),
            if (isFamily) ...[
              const SizedBox(height: NestSpace.sm),
              NestButton(
                label: SubscriptionCopy.seePremium,
                icon: LucideIcons.award,
                variant: NestButtonVariant.outline,
                onPressed: () =>
                    showPaywall(context, feature: PremiumFeature.householdSize),
              ),
            ],
            if (canOpenAssistants) ...[
              const SizedBox(height: NestSpace.xl),
              AssistantsLink(householdId: view.household.id),
            ],
          ],
        ),
      ),
    );
  }
}
