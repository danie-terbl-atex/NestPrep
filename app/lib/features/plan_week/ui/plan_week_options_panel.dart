import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/flags/feature_flag.dart';
import '../../../shared/flags/feature_flags_controller.dart';
import '../../lunch_box/model/lunch_board.dart';
import '../../lunch_box/state/lunch_pantry_controller.dart';
import '../../subscriptions/model/premium_feature.dart';
import '../../subscriptions/ui/premium_gate.dart';
import '../model/plan_week_options.dart';
import '../state/plan_week_controller.dart';
import 'plan_week_toggle_row.dart';

/// What to plan: whose lunches, whether dinners, and the two leanings — the
/// pantry and a thrifty week — each only while its own switch is on
/// (foundation ADR-0014). Then one button, behind premium.
class PlanWeekOptionsPanel extends StatelessWidget {
  const PlanWeekOptionsPanel({required this.board, super.key});

  final LunchBoard board;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final controller = context.watch<PlanWeekController>();
    final flags = context.watch<FeatureFlagsController?>();
    final hasPantry = flags?.isOn(FeatureFlag.lunchPantry) ?? false;
    final hasBudget = flags?.isOn(FeatureFlag.lunchBudget) ?? false;
    final options = controller.options;
    final failure = controller.failure;
    final toggles = <Widget>[
      if (controller.mayPlanDinners)
        PlanWeekToggleRow(
          icon: Icons.dinner_dining_outlined,
          tint: NestTileTint.peach,
          title: PlanWeekCopy.dinnersTitle,
          subtitle: options.includeDinners
              ? PlanWeekCopy.dinnersOn
              : PlanWeekCopy.dinnersOff,
          value: options.includeDinners,
          onChanged: (value) =>
              controller.setOptions(options.copyWith(includeDinners: value)),
        ),
      if (hasPantry)
        PlanWeekToggleRow(
          icon: Icons.kitchen_outlined,
          tint: NestTileTint.mint,
          title: PlanWeekCopy.pantryTitle,
          subtitle: PlanWeekCopy.pantryBody,
          value: options.useWhatsInTheHouse,
          onChanged: (value) => controller.setOptions(
            options.copyWith(useWhatsInTheHouse: value),
          ),
        ),
      if (hasBudget)
        PlanWeekToggleRow(
          icon: Icons.savings_outlined,
          tint: NestTileTint.pink,
          title: PlanWeekCopy.budgetTitle,
          subtitle: PlanWeekCopy.budgetBody,
          value: options.budget == PlanBudget.thrifty,
          onChanged: (value) => controller.setOptions(
            options.copyWith(
              budget: value ? PlanBudget.thrifty : PlanBudget.none,
            ),
          ),
        ),
    ];

    return ListView(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      children: [
        NestRiseIn(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const NestIconTile(
                icon: Icons.auto_awesome_rounded,
                tint: NestTileTint.sky,
              ),
              const SizedBox(width: NestSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      PlanWeekCopy.chooseHeadline,
                      style: nest.text.headline,
                    ),
                    const SizedBox(height: NestSpace.xs),
                    Text(
                      PlanWeekCopy.chooseBody,
                      style: nest.text.bodySecondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: NestSpace.xl),
        const NestRiseIn(
          index: 1,
          child: NestSectionHeader(title: PlanWeekCopy.lunchesFor),
        ),
        const SizedBox(height: NestSpace.sm),
        NestRiseIn(
          index: 1,
          child: board.children.isEmpty
              ? Text(PlanWeekCopy.noChildren, style: nest.text.bodySecondary)
              : Wrap(
                  spacing: NestSpace.sm,
                  runSpacing: NestSpace.sm,
                  children: [
                    for (final child in board.children)
                      NestChip(
                        key: ValueKey('plan-child-${child.childId}'),
                        label: child.child.member.displayName,
                        isSelected: options.childIds.contains(child.childId),
                        icon: options.childIds.contains(child.childId)
                            ? Icons.check_rounded
                            : Icons.add_rounded,
                        onTap: () => controller.setOptions(
                          options.toggleChild(child.childId),
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: NestSpace.xl),
        if (toggles.isNotEmpty)
          NestRiseIn(
            index: 2,
            child: NestCard(
              padding: const EdgeInsets.symmetric(vertical: NestSpace.sm),
              child: Column(children: toggles),
            ),
          ),
        if (failure != null) ...[
          const SizedBox(height: NestSpace.lg),
          NestBanner(
            message: AppCopy.failure(failure),
            tone: NestBannerTone.danger,
            actionLabel: AppCopy.back,
            onAction: controller.dismissFailure,
          ),
        ],
        const SizedBox(height: NestSpace.xl),
        NestRiseIn(
          index: 3,
          child: NestButton(
            key: const ValueKey('plan-week-go'),
            label: PlanWeekCopy.planAction,
            icon: Icons.auto_awesome_rounded,
            onPressed: controller.isReady && options.hasSomethingToPlan
                ? () => _plan(context, controller, usePantry: hasPantry)
                : null,
          ),
        ),
        const SizedBox(height: NestSpace.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: NestSize.iconSmall,
              color: nest.colors.inkTertiary,
            ),
            const SizedBox(width: NestSpace.sm),
            Expanded(
              child: Text(PlanWeekCopy.privacyNote, style: nest.text.caption),
            ),
          ],
        ),
      ],
    );
  }

  /// Premium first (subscriptions ADR-0001), then the plan — the server
  /// checks premium again and its answer is the one that counts (`FE-04`).
  static Future<void> _plan(
    BuildContext context,
    PlanWeekController controller, {
    required bool usePantry,
  }) async {
    final pantry = usePantry ? context.read<LunchPantryController>() : null;
    if (!await ensurePremium(context, feature: PremiumFeature.aiPlanning)) {
      return;
    }
    await controller.plan(pantryBias: pantry?.bias);
  }
}
