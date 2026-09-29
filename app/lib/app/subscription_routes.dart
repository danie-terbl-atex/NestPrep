import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/household/model/household_view.dart';
import '../features/subscriptions/data/store_billing.dart';
import '../features/subscriptions/state/plan_controller.dart';
import '../features/subscriptions/state/purchase_coordinator.dart';
import '../features/subscriptions/ui/plan_screen.dart';
import '../shared/links/external_link_opener.dart';
import 'subscription_route.dart';

/// Subscriptions' route under the household shell (subscriptions ADR-0001),
/// in its own file so the route table gains one line. The plan itself is
/// the shell's entitlement listener; the route adds only the screen's
/// actions.
GoRoute subscriptionRoute() => GoRoute(
  path: SubscriptionRoute.path,
  builder: (context, state) => ChangeNotifierProvider(
    create: (context) => PlanController(
      storeBilling: context.read<StoreBilling>(),
      purchaseCoordinator: context.read<PurchaseCoordinator>(),
      linkOpener: context.read<ExternalLinkOpener>(),
      viewerMemberId: context.read<HouseholdView>().viewerMember?.id,
    ),
    child: const PlanScreen(),
  ),
);
