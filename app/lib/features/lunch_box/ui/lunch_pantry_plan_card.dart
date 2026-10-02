import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/lunch_planning_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../household/model/household_view.dart';
import '../model/lunch_board.dart';
import '../model/lunch_pantry_week.dart';
import '../state/lunch_board_controller.dart';
import '../state/lunch_pantry_controller.dart';
import 'lunch_packed_today.dart';

/// Planning from what is in the house, on the lunch board (lunch-box
/// ADR-0006): the switch, *Fill from the pantry* while it is on, what the
/// week still needs, and — on a school day — marking today's box packed.
class LunchPantryPlanCard extends StatelessWidget {
  const LunchPantryPlanCard({
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
    final pantry = context.watch<LunchPantryController>();
    final lunch = context.watch<LunchBoardController>();
    final isOn = pantry.isPlanningFromPantry;
    final state = pantry.pantry;
    return NestCard(
      child: Column(
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
          switch (state) {
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
            AsyncData(:final value) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isOn && canEdit) ...[
                  const SizedBox(height: NestSpace.sm),
                  NestButton(
                    label: LunchPantryCopy.fillFromPantry,
                    icon: LucideIcons.sparkles,
                    isLoading: lunch.edit.isFilling,
                    onPressed: () => lunch.edit.autoFill(
                      childWeek.childId,
                      bias: pantry.bias,
                    ),
                  ),
                ],
                const SizedBox(height: NestSpace.md),
                _WeekNeeds(week: value),
                if (canEdit)
                  LunchPackedToday(
                    board: board,
                    childWeek: childWeek,
                    pantry: value,
                  ),
              ],
            ),
          },
        ],
      ),
    );
  }
}

/// One line on what the week still needs, and the way to the pantry.
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
