import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/lunch_planning_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/flags/feature_flag.dart';
import '../../../shared/flags/feature_flags_controller.dart';
import '../../household/model/household_view.dart';
import '../../subscriptions/model/premium_feature.dart';
import '../../subscriptions/state/household_entitlement.dart';
import '../../subscriptions/ui/premium_gate.dart';
import '../model/lunch_board.dart';
import 'lunch_budget_strip.dart';
import 'lunch_pantry_plan_card.dart';

/// Lunch-box's V2 tools on the lunch board (lunch-box ADR-0006 to ADR-0008):
/// the ways into the pantry, budget mode and kid picks, the pantry's card,
/// and the week's spend. Each is there only when its switch is on
/// (foundation ADR-0014); with all three off this is nothing at all.
class LunchPlanningTools extends StatelessWidget {
  const LunchPlanningTools({
    required this.board,
    required this.childWeek,
    required this.canEdit,
    super.key,
  });

  final LunchBoard board;
  final LunchChildWeek childWeek;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    final flags = context.watch<FeatureFlagsController?>();
    final hasPantry = flags?.isOn(FeatureFlag.lunchPantry) ?? false;
    final hasBudget = flags?.isOn(FeatureFlag.lunchBudget) ?? false;
    final hasKidPicks =
        canEdit && (flags?.isOn(FeatureFlag.lunchKidPicks) ?? false);
    if (!hasPantry && !hasBudget && !hasKidPicks) {
      return const SizedBox.shrink();
    }
    final isPremium = context.watch<HouseholdEntitlement>().isPremium;
    final householdId = context.read<HouseholdView>().household.id;
    return Padding(
      padding: const EdgeInsets.only(top: NestSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: NestSpace.sm,
            runSpacing: NestSpace.sm,
            children: [
              if (hasPantry)
                _ToolButton(
                  label: LunchPlanningCopy.openPantry,
                  icon: LucideIcons.refrigerator,
                  onPressed: () => context.push(
                    LunchPlanningRoute.pantryPathFor(householdId),
                  ),
                ),
              if (hasBudget)
                _ToolButton(
                  label: isPremium
                      ? LunchPlanningCopy.openBudget
                      : '${LunchPlanningCopy.openBudget} · '
                            '${LunchPlanningCopy.premiumHint}',
                  icon: isPremium ? LucideIcons.piggyBank : LucideIcons.award,
                  onPressed: () => _openBudget(context, householdId),
                ),
              if (hasKidPicks)
                _ToolButton(
                  label: LunchPlanningCopy.openKidPicks,
                  icon: LucideIcons.pointer,
                  onPressed: () => context.push(
                    LunchPlanningRoute.picksPathFor(householdId),
                  ),
                ),
            ],
          ),
          if (hasPantry) ...[
            const SizedBox(height: NestSpace.md),
            LunchPantryPlanCard(
              board: board,
              childWeek: childWeek,
              canEdit: canEdit,
            ),
          ],
          if (hasBudget && isPremium) ...[
            const SizedBox(height: NestSpace.sm),
            const LunchBudgetStrip(),
          ],
        ],
      ),
    );
  }

  /// Premium first, then the screen (subscriptions ADR-0001).
  static Future<void> _openBudget(
    BuildContext context,
    String householdId,
  ) async {
    final router = GoRouter.of(context);
    if (!await ensurePremium(context, feature: PremiumFeature.budgetMode)) {
      return;
    }
    await router.push<void>(LunchPlanningRoute.budgetPathFor(householdId));
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => NestButton(
    label: label,
    icon: icon,
    variant: NestButtonVariant.tonal,
    size: NestButtonSize.small,
    isExpanded: false,
    onPressed: onPressed,
  );
}
