import 'package:flutter/widgets.dart';

import '../../subscriptions/ui/paywall_sheet.dart';
import '../state/new_child_marking.dart';

/// A second child on a free household is still added; the paywall is the
/// answer to planning for them, and buying marks them after all (household
/// ADR-0009, subscriptions ADR-0001).
Future<void> offerPremiumForNewChild(
  BuildContext context,
  MakesChildren controller,
) async {
  final feature = controller.childAwaitingPremium;
  if (feature == null || !context.mounted) return;
  final upgraded = await showPaywall(context, feature: feature);
  if (upgraded) {
    await controller.markChildAfterUpgrade();
  } else {
    controller.forgetChildAwaitingPremium();
  }
}
