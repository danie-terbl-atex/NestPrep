import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/flags/feature_flag.dart';
import '../../../shared/flags/feature_flags.dart';
import '../../../shared/flags/feature_flags_controller.dart';
import '../../groceries/model/product_match.dart';
import '../../plan_week/ui/plan_week_entry_card.dart';
import '../../subscriptions/state/household_entitlement.dart';
import '../../welcome_tour/model/tour_target.dart';
import '../../welcome_tour/ui/tour_anchor.dart';
import '../model/lunch_board.dart';
import '../model/lunch_plan_way.dart';
import '../model/lunch_tool.dart';
import '../state/lunch_board_controller.dart';
import '../state/lunch_pantry_controller.dart';
import '../state/lunch_variety_choice.dart';
import 'lunch_budget_strip.dart';
import 'lunch_flows.dart';
import 'lunch_pantry_plan.dart';
import 'lunch_plan_week_sheet.dart';
import 'lunch_week_name.dart';

/// The whole week's planner under the week's name (lunch-box ADR-0022,
/// ADR-0033): one *Plan the week* button that asks how — Twig at the shop
/// (ADR-0012, premium), the boxes yourself (ADR-0020), or the pantry
/// (ADR-0006) — then the pantry switch and the week's spend (ADR-0007).
/// Only for somebody who may change lunches; the board does not build it
/// otherwise.
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
    final isPremium = context.watch<HouseholdEntitlement>().isPremium;
    final hasBudget =
        (flags?.isOn(FeatureFlag.lunchBudget) ?? false) && isPremium;
    final shop = PlanWeekEntry.shopFor(context, board);
    final isFull = childWeek.filledDays == childWeek.days.length;
    final ways = LunchPlanWay.offered(
      hasTwig: shop != null,
      hasPantry:
          hasPantry && context.watch<LunchPantryController>().bias != null,
      isPremium: isPremium,
      isFull: isFull,
    );
    return NestCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TourAnchor(
            target: TourTarget.lunchPlanMyWeek,
            child: NestButton(
              key: const ValueKey('plan-week-choose'),
              label: LunchCopy.planWeek,
              icon: LucideIcons.sparkles,
              isLoading: controller.edit.isFilling,
              onPressed: ways.isEmpty
                  ? null
                  : () => _plan(context, ways: ways, shop: shop),
            ),
          ),
          const SizedBox(height: NestSpace.sm),
          Text(
            isFull ? LunchCopy.weekIsFull : LunchCopy.planWeekHint,
            textAlign: TextAlign.center,
            style: nest.text.caption,
          ),
          if (hasPantry) ...[
            const Divider(height: NestSpace.xxl),
            const LunchPantryPlan(),
          ],
          if (hasBudget) const LunchBudgetStrip(),
        ],
      ),
    );
  }

  Future<void> _plan(
    BuildContext context, {
    required List<LunchPlanWay> ways,
    required ProductRetailer? shop,
  }) async {
    final way = ways.length == 1
        ? ways.single
        : await showLunchPlanWeekSheet(
            context: context,
            week: LunchWeekName.ofBoard(board).inSentence,
            ways: ways,
            shop: shop,
            isPremium: context.read<HouseholdEntitlement>().isPremium,
          );
    if (way == null || !context.mounted) return;
    switch (way) {
      case LunchPlanWay.twig:
        await PlanWeekEntry.open(context);
      case LunchPlanWay.boxes:
        await LunchFlows.fillWeek(context, childWeek: childWeek);
      case LunchPlanWay.pantry:
        await context.read<LunchBoardController>().edit.autoFill(
          childWeek.childId,
          bias: context.read<LunchPantryController>().bias,
          variety: context.read<LunchVarietyChoice>().variety,
        );
    }
  }
}
