import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../../shared/async/async_state.dart';
import '../model/premium_feature.dart';
import '../state/household_entitlement.dart';
import 'paywall_page.dart';

/// The one call a premium feature makes before it opens (subscriptions
/// ADR-0001): true when the household has premium, or once the person has
/// bought it from the paywall this opens on [feature]; false when they
/// chose not to.
///
/// This decides only what is shown first. The write behind the feature is
/// refused by the rules' `hasPremium` regardless (`FE-04`, `BE-20`), so a
/// screen that skipped this would meet the refusal, not a free premium.
///
/// An entitlement that has not answered yet is waited for briefly, and one
/// that cannot be read lets the person through to the server's own answer:
/// a paying household is never shown the paywall because of a slow start.
Future<bool> ensurePremium(
  BuildContext context, {
  required PremiumFeature feature,
}) async {
  final entitlement = context.read<HouseholdEntitlement>();
  if (entitlement.isPremium) return true;
  if (entitlement.entitlement is AsyncLoading) {
    await _answered(entitlement);
    if (!context.mounted) return false;
    if (entitlement.isPremium) return true;
  }
  if (!entitlement.isKnown) return true;
  return showPaywall(context, feature: feature);
}

Future<void> _answered(HouseholdEntitlement entitlement) {
  final answered = Completer<void>();
  void listener() {
    if (entitlement.entitlement is AsyncLoading || answered.isCompleted) return;
    answered.complete();
  }

  entitlement.addListener(listener);
  return answered.future
      .timeout(const Duration(seconds: 5), onTimeout: () {})
      .whenComplete(() => entitlement.removeListener(listener));
}
