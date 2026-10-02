import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../subscriptions/model/premium_feature.dart';
import '../../subscriptions/ui/paywall_sheet.dart';

/// Budget mode for a household without premium (lunch-box ADR-0007): what
/// it would do, and the way to it — never a dead end, and never a write the
/// rules would refuse.
class LunchBudgetLocked extends StatelessWidget {
  const LunchBudgetLocked({super.key});

  @override
  Widget build(BuildContext context) => NestEmptyView(
    icon: LucideIcons.piggyBank,
    title: LunchBudgetCopy.lockedTitle,
    message: LunchBudgetCopy.lockedBody,
    actionLabel: LunchBudgetCopy.seePremium,
    onAction: () => showPaywall(context, feature: PremiumFeature.budgetMode),
  );
}
