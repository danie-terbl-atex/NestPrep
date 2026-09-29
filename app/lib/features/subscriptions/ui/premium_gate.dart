import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../model/premium_feature.dart';
import '../state/household_entitlement.dart';
import 'paywall_sheet.dart';

/// The one call a premium feature makes before it opens (subscriptions
/// ADR-0001): true when the household has premium, or once the person has
/// bought it from the paywall this opens on [feature]; false when they
/// chose not to.
///
/// This decides only what is shown first. The write behind the feature is
/// refused by the rules' `hasPremium` regardless (`FE-04`, `BE-20`), so a
/// screen that skipped this would meet the refusal, not a free premium.
/// Lunch-box's learning loop and prep list are its first callers.
Future<bool> ensurePremium(
  BuildContext context, {
  required PremiumFeature feature,
}) async {
  if (context.read<HouseholdEntitlement>().isPremium) return true;
  return showPaywall(context, feature: feature);
}
