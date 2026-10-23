import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/flags/feature_flag.dart';
import '../../../shared/flags/feature_flags.dart';
import '../../../shared/flags/feature_flags_controller.dart';
import '../../plan_week/ui/plan_week_entry_card.dart';
import '../../subscriptions/state/household_entitlement.dart';
import '../../welcome_tour/model/tour_target.dart';
import '../../welcome_tour/ui/tour_anchor.dart';
import '../model/lunch_board.dart';
import '../model/lunch_tool.dart';
import '../state/lunch_board_controller.dart';
import 'lunch_budget_strip.dart';
import 'lunch_flows.dart';
import 'lunch_pantry_plan.dart';

/// Every way to plan the whole week, in one place under the week's name
/// (lunch-box ADR-0022): *Fill the week* first, because it is free and the
/// core (ADR-0003, ADR-0004); then planning from the pantry (ADR-0006,
/// `lunchPantry`); then *Plan my week from Checkers* as a quieter option
/// (ADR-0012, `planMyWeek`, premium); then the week's spend (ADR-0007,
/// `lunchBudget`, premium). Each keeps the switch and the premium line it
/// always had. Only for somebody who may change lunches — the board does
/// not build it otherwise.
class LunchWeekPlanner extends StatelessWidget {
  const LunchWeekPlanner({
    required this.board,
    required this.childWeek,
    super.key,
  });

  final LunchBoard board;
  final LunchChildWeek childWeek;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final controller = context.watch<LunchBoardController>();
    final flags = context.watch<FeatureFlagsController?>();
    // The same answer the welcome tour reads (welcome-tour ADR-0001).
    final hasPantry = LunchTool.pantryPlan.isOpenTo(
      canEdit: true,
      flags: flags?.flags ?? const FeatureFlags.defaults(defaultOn: false),
    );
    final hasBudget =
        (flags?.isOn(FeatureFlag.lunchBudget) ?? false) &&
        context.watch<HouseholdEntitlement>().isPremium;
    final isFull = childWeek.filledDays == childWeek.days.length;
    return NestCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(LunchCopy.planWholeWeek, style: nest.text.title),
          const SizedBox(height: NestSpace.md),
          NestButton(
            label: LunchCopy.fillWeek,
            icon: LucideIcons.sparkles,
            isLoading: controller.edit.isFilling,
            onPressed: isFull
                ? null
                : () => LunchFlows.fillWeek(context, childWeek: childWeek),
          ),
          const SizedBox(height: NestSpace.sm),
          Text(
            isFull ? LunchCopy.weekIsFull : LunchCopy.fillWeekHint,
            textAlign: TextAlign.center,
            style: nest.text.caption,
          ),
          if (hasPantry) ...[
            const Divider(height: NestSpace.xxl),
            LunchPantryPlan(childWeek: childWeek),
          ],
          TourAnchor(
            target: TourTarget.lunchPlanMyWeek,
            child: PlanWeekEntryCard(board: board, canEdit: true),
          ),
          if (hasBudget) const LunchBudgetStrip(),
        ],
      ),
    );
  }
}
