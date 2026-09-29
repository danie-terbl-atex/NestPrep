import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../subscriptions/model/premium_feature.dart';
import '../../subscriptions/state/household_entitlement.dart';
import '../../subscriptions/ui/paywall_sheet.dart';
import '../../subscriptions/ui/premium_gate.dart';

/// Where lunch-box's free tier ends, asked before a flow opens (lunch-box
/// ADR-0009): true when the household may go on, or once somebody bought
/// premium from the paywall this opened; false when they chose not to.
///
/// This decides only what is shown first. The writes behind each are
/// refused by the rules without premium regardless (`FE-04`, `BE-20`).
abstract final class LunchPremium {
  /// Before anything is written to [childId]'s week: a free household plans
  /// one child, the one its first marking recorded.
  static Future<bool> mayPlan(BuildContext context, String childId) async {
    if (context.read<HouseholdEntitlement>().plansChild(childId)) return true;
    return showPaywall(context, feature: PremiumFeature.additionalChild);
  }

  /// Before a box is marked eaten or left: learning from what came home.
  static Future<bool> mayLearn(BuildContext context, String childId) async =>
      await ensurePremium(context, feature: PremiumFeature.lunchLearning) &&
      context.mounted &&
      await mayPlan(context, childId);

  /// Before the Sunday prep list opens.
  static Future<bool> mayPrep(BuildContext context) =>
      ensurePremium(context, feature: PremiumFeature.prepList);
}
