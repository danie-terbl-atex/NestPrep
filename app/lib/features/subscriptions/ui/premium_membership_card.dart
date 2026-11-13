import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/subscription_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/subscription_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/time/household_clock.dart';
import '../../household/model/household_view.dart';
import '../model/entitlement.dart';
import '../model/entitlement_status.dart';
import '../state/household_entitlement.dart';

/// What a household with Premium reads at the top of More (subscriptions
/// ADR-0007). Family, who buy it, also read how long it runs and can open
/// plan and billing from it; for anybody else it is not a control.
class PremiumMembershipCard extends StatelessWidget {
  const PremiumMembershipCard({super.key});

  @override
  Widget build(BuildContext context) {
    final view = context.watch<HouseholdView>();
    final household = context.watch<HouseholdEntitlement>();
    final entitlement = switch (household.entitlement) {
      AsyncData(:final value) => value,
      _ => null,
    };
    final until = entitlement?.premiumUntil;
    final isFamily = view.permissions.isFamily;
    return NestPremiumCard(
      title: SubscriptionCopy.membershipTitle,
      body: SubscriptionCopy.membershipBody(view.household.name),
      detail: isFamily && entitlement != null && until != null
          ? _runs(
              entitlement,
              _dateLabel(context.read<HouseholdClock>(), until),
              household.now(),
            )
          : null,
      // Pushed, so back lands on More (`FE-17`).
      onTap: isFamily
          ? () => context.push(SubscriptionRoute.pathFor(view.household.id))
          : null,
    );
  }

  static String _dateLabel(HouseholdClock clock, DateTime at) =>
      NestDates.full(clock.dateOf(at), clock.today);

  static String _runs(Entitlement entitlement, String until, DateTime now) {
    if (entitlement.isGivenOnlyAt(now)) {
      return SubscriptionCopy.givenUntil(until);
    }
    if (entitlement.status == EntitlementStatus.inGracePeriod) {
      return SubscriptionCopy.graceUntil(until);
    }
    return entitlement.isRenewing
        ? SubscriptionCopy.renewsOn(until)
        : SubscriptionCopy.endsOn(until);
  }
}
