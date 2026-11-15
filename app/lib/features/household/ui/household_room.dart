import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../../shared/failure/app_failure.dart';
import '../../../shared/state/action_failure.dart';
import '../../subscriptions/model/premium_feature.dart';
import '../../subscriptions/state/household_entitlement.dart';
import '../../subscriptions/ui/paywall_page.dart';
import '../../subscriptions/ui/premium_gate.dart';
import '../model/household_view.dart';

/// Whether adding a person here opens the paywall instead of the form: a
/// household without Premium that already holds the free plan's four
/// (subscriptions ADR-0008).
bool isFullOnFreePlan(BuildContext context, HouseholdView view) {
  final entitlement = context.watch<HouseholdEntitlement>();
  return view.fillsFreePlan && entitlement.isKnown && !entitlement.isPremium;
}

/// True when there is room for one more person, or once the household has
/// bought the room from the paywall this opens.
Future<bool> ensureRoomForAnother(
  BuildContext context,
  HouseholdView view,
) async {
  if (!view.fillsFreePlan) return true;
  return ensurePremium(context, feature: PremiumFeature.householdSize);
}

/// A profile the rules refused while the free plan is full — somebody else
/// added the fourth a moment ago — is answered with the paywall, not a
/// banner. [view] is the household as it stands now, not as it stood when the
/// form opened. Any other refusal stays what it was.
Future<void> offerRoomIfRefused(
  BuildContext context,
  ActionFailureHolder controller,
  HouseholdView? view,
) async {
  if (controller.actionFailure is! PermissionDeniedFailure) return;
  if (view == null || !view.fillsFreePlan) return;
  final entitlement = context.read<HouseholdEntitlement>();
  if (!entitlement.isKnown || entitlement.isPremium) return;
  controller.dismissActionFailure();
  await showPaywall(context, feature: PremiumFeature.householdSize);
}
