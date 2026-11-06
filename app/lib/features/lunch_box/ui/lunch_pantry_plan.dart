import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/lunch_planning_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../household/model/household_view.dart';
import '../model/lunch_pantry_week.dart';
import '../state/lunch_pantry_controller.dart';

/// Planning the week from what is in the house, inside the week's planner
/// (lunch-box ADR-0006, ADR-0022): the switch and what the week still needs.
/// While it is on, *Plan the week* offers *Fill from the pantry*
/// (ADR-0033). Marking today's box packed is about the day, so it sits with
/// the day on show instead.
class LunchPantryPlan extends StatelessWidget {
  const LunchPantryPlan({super.key});

  @override
  Widget build(BuildContext context) {
    final pantry = context.watch<LunchPantryController>();
    final isOn = pantry.isPlanningFromPantry;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NestListRow(
          title: LunchPantryCopy.planFromPantry,
          subtitle: isOn
              ? LunchPantryCopy.planFromPantryOn
              : LunchPantryCopy.planFromPantryOff,
          leading: const NestIconTile(
            icon: LucideIcons.refrigerator,
            tint: NestTileTint.basil,
            size: NestSize.avatarMedium,
          ),
          trailing: Switch(
            value: isOn,
            onChanged: (value) => pantry.setPlanningFromPantry(isOn: value),
          ),
          onTap: () => pantry.setPlanningFromPantry(isOn: !isOn),
        ),
        switch (pantry.pantry) {
          AsyncLoading() => const Padding(
            padding: EdgeInsets.only(top: NestSpace.sm),
            child: NestSkeleton(height: NestSpace.xxl),
          ),
          AsyncFailure(:final failure) => NestBanner(
            message: AppCopy.failure(failure),
            tone: NestBannerTone.danger,
            actionLabel: AppCopy.retry,
            onAction: pantry.retry,
          ),
          AsyncData(:final value) => Padding(
            padding: const EdgeInsets.only(top: NestSpace.md),
            child: _WeekNeeds(week: value),
          ),
        },
      ],
    );
  }
}

/// One line on what the week still needs — none while no box holds
/// anything — and the way to the pantry.
class _WeekNeeds extends StatelessWidget {
  const _WeekNeeds({required this.week});

  final LunchPantryWeek week;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final householdId = context.read<HouseholdView>().household.id;
    final count = week.shortfall.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (week.hasBoxesToPack)
          Text(
            count == 0
                ? LunchPantryCopy.weekCovered
                : LunchPantryCopy.weekNeeds(count),
            style: nest.text.bodySecondary,
          ),
        NestButton(
          label: LunchPantryCopy.seeWhatIsMissing,
          icon: LucideIcons.arrowRight,
          variant: NestButtonVariant.ghost,
          size: NestButtonSize.small,
          isExpanded: false,
          onPressed: () =>
              context.push(LunchPlanningRoute.pantryPathFor(householdId)),
        ),
      ],
    );
  }
}
