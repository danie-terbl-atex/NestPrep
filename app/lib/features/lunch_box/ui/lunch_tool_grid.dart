import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/lunch_planning_route.dart';
import '../../../app/lunch_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/flags/feature_flags.dart';
import '../../../shared/flags/feature_flags_controller.dart';
import '../../household/model/household_view.dart';
import '../../subscriptions/model/premium_feature.dart';
import '../../subscriptions/state/household_entitlement.dart';
import '../../subscriptions/ui/premium_gate.dart';
import '../../welcome_tour/model/tour_target.dart';
import '../../welcome_tour/ui/tour_anchor.dart';
import '../model/lunch_tool.dart';
import 'lunch_flows.dart';

/// The places lunch-box keeps beside the board, last on it and as one grid of
/// named tiles (lunch-box ADR-0022, the kit's place tiles from design-system
/// ADR-0005): the Sunday prep list (premium, asked first — ADR-0009), the
/// library and sharing (for somebody who may change lunches — ADR-0004,
/// ADR-0005), and the V2 tools, each only while its switch is on (foundation
/// ADR-0014): the pantry, budget mode (premium, and says so — ADR-0007) and
/// kid picks (for an editor) — as [LunchTool] decides for the welcome tour
/// too (welcome-tour ADR-0001). Every tile pushes; what each place may do is
/// still that place's and the rules' to say (`FE-04`).
class LunchToolGrid extends StatelessWidget {
  const LunchToolGrid({required this.canEdit, super.key});

  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    final tools = LunchTool.openOf(
      LunchTool.grid,
      canEdit: canEdit,
      flags:
          context.watch<FeatureFlagsController?>()?.flags ??
          const FeatureFlags.defaults(defaultOn: false),
    );
    final isPremium = context.watch<HouseholdEntitlement>().isPremium;
    final householdId = context.read<HouseholdView>().household.id;
    void open(String path) => context.push(path);
    return NestPlaceGrid(
      children: [
        if (tools.contains(LunchTool.prep))
          TourAnchor(
            target: TourTarget.lunchPrep,
            child: NestPlaceTile(
              icon: LucideIcons.soup,
              tint: NestTileTint.butter,
              title: LunchCopy.openPrep,
              subtitle: LunchCopy.prepBody,
              onTap: () => LunchFlows.openPrep(
                context,
                path: LunchRoute.prepPathFor(householdId),
              ),
            ),
          ),
        if (tools.contains(LunchTool.library))
          NestPlaceTile(
            icon: LucideIcons.bookOpen,
            title: LunchCopy.openLibrary,
            subtitle: LunchCopy.librarySubtitle,
            onTap: () => open(LunchRoute.libraryPathFor(householdId)),
          ),
        if (tools.contains(LunchTool.share))
          NestPlaceTile(
            icon: LucideIcons.share,
            tint: NestTileTint.lilac,
            title: LunchShareCopy.openShare,
            subtitle: LunchCopy.shareBody,
            onTap: () => open(LunchRoute.sharePathFor(householdId)),
          ),
        if (tools.contains(LunchTool.pantry))
          NestPlaceTile(
            icon: LucideIcons.refrigerator,
            tint: NestTileTint.basil,
            title: LunchPlanningCopy.openPantry,
            subtitle: LunchPlanningCopy.pantryBody,
            onTap: () => open(LunchPlanningRoute.pantryPathFor(householdId)),
          ),
        if (tools.contains(LunchTool.budget))
          TourAnchor(
            target: TourTarget.lunchBudget,
            child: NestPlaceTile(
              icon: isPremium ? LucideIcons.piggyBank : LucideIcons.award,
              tint: NestTileTint.guava,
              title: LunchPlanningCopy.openBudget,
              subtitle: isPremium
                  ? LunchPlanningCopy.budgetBody
                  : LunchPlanningCopy.premiumHint,
              onTap: () => _openBudget(context, householdId),
            ),
          ),
        if (tools.contains(LunchTool.kidPicks))
          NestPlaceTile(
            icon: LucideIcons.pointer,
            tint: NestTileTint.lilac,
            title: LunchPlanningCopy.openKidPicks,
            subtitle: LunchPlanningCopy.kidPicksBody,
            onTap: () => open(LunchPlanningRoute.picksPathFor(householdId)),
          ),
      ],
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
