import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/plan_week_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/flags/feature_flag.dart';
import '../../../shared/flags/feature_flags_controller.dart';
import '../../household/model/household_view.dart';
import '../../lunch_box/model/lunch_board.dart';
import '../../subscriptions/model/premium_feature.dart';
import '../../subscriptions/state/household_entitlement.dart';
import '../../subscriptions/ui/premium_gate.dart';

/// *Plan my week from Checkers* on the lunch board (lunch-box ADR-0012): the one way in,
/// for somebody who may change lunches, while its switch is on (foundation
/// ADR-0014), on a week that has not gone. Premium says so on the card and
/// opens the paywall first; the server checks premium again (`FE-04`).
class PlanWeekEntryCard extends StatelessWidget {
  const PlanWeekEntryCard({
    required this.board,
    required this.canEdit,
    super.key,
  });

  final LunchBoard board;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    final flags = context.watch<FeatureFlagsController?>();
    final isOn = flags?.isOn(FeatureFlag.planMyWeek) ?? false;
    final hasGone = board.today.isAfter(board.week.monday.addDays(6));
    if (!isOn || !canEdit || hasGone) return const SizedBox.shrink();
    final nest = NestTheme.of(context);
    final isPremium = context.watch<HouseholdEntitlement>().isPremium;
    return Padding(
      padding: const EdgeInsets.only(bottom: NestSpace.md),
      child: NestCard(
        variant: NestCardVariant.tinted,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const NestIconTile(
                  icon: LucideIcons.sparkles,
                  tint: NestTileTint.lilac,
                ),
                const SizedBox(width: NestSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(PlanWeekCopy.entryTitle, style: nest.text.title),
                      const SizedBox(height: NestSpace.xs),
                      Text(
                        PlanWeekCopy.entryBody,
                        style: nest.text.bodySecondary,
                      ),
                      if (!isPremium) ...[
                        const SizedBox(height: NestSpace.sm),
                        const NestTag(
                          label: PlanWeekCopy.premiumTag,
                          tone: NestTagTone.accent,
                          icon: LucideIcons.award,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: NestSpace.lg),
            NestButton(
              key: const ValueKey('plan-week-open'),
              label: PlanWeekCopy.entryAction,
              icon: LucideIcons.sparkles,
              onPressed: () => _open(context),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _open(BuildContext context) async {
    final router = GoRouter.of(context);
    final householdId = context.read<HouseholdView>().household.id;
    if (!await ensurePremium(context, feature: PremiumFeature.aiPlanning)) {
      return;
    }
    await router.push<void>(PlanWeekRoute.pathFor(householdId));
  }
}
