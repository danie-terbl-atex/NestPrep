import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../model/planned_week.dart';
import '../state/plan_week_controller.dart';
import 'plan_week_dinner_sheet.dart';

/// The week's dinners on the review, Monday to Sunday: what was planned
/// already, quiet; what the plan adds, a tap from being changed; and a new
/// idea with what it needs, marked to be checked — a meal nobody has cooked
/// carries no allergen codes (lunch-box ADR-0011).
class PlanWeekDinnersCard extends StatelessWidget {
  const PlanWeekDinnersCard({
    required this.planned,
    required this.isEditable,
    super.key,
  });

  final PlannedWeek planned;
  final bool isEditable;

  @override
  Widget build(BuildContext context) => NestCard(
    padding: const EdgeInsets.symmetric(vertical: NestSpace.sm),
    child: Column(
      children: [
        for (var day = 1; day <= 7; day++)
          _DinnerRow(
            key: ValueKey('plan-dinner-$day'),
            day: day,
            planned: planned,
            isEditable: isEditable,
          ),
      ],
    ),
  );
}

class _DinnerRow extends StatelessWidget {
  const _DinnerRow({
    required this.day,
    required this.planned,
    required this.isEditable,
    super.key,
  });

  final int day;
  final PlannedWeek planned;
  final bool isEditable;

  @override
  Widget build(BuildContext context) {
    final date = planned.week.monday.addDays(day - 1);
    final dayName = NestDates.weekdayName(date);
    final existing = planned.existingDinners[day];
    if (existing != null) {
      return NestListRow(
        title: existing.name,
        subtitle: '$dayName · ${PlanWeekCopy.alreadyPlanned}',
        leading: const NestIconTile(
          icon: Icons.check_rounded,
          tint: NestTileTint.mint,
          size: NestSize.avatarMedium,
          iconSize: NestSize.iconMedium,
        ),
      );
    }
    final dinner = planned.dinners[day];
    final onTap = isEditable ? () => _change(context, dayName) : null;
    return switch (dinner) {
      null => NestListRow(
        title: PlanWeekCopy.noDinner,
        subtitle: dayName,
        leading: const NestIconTile(
          icon: Icons.add_rounded,
          tint: NestTileTint.sky,
          size: NestSize.avatarMedium,
          iconSize: NestSize.iconMedium,
        ),
        onTap: onTap,
      ),
      LibraryDinner(:final meal, :final origin) => NestListRow(
        title: meal.name,
        subtitle: '$dayName · ${_originWords(origin)}',
        leading: const NestIconTile(
          icon: Icons.dinner_dining_outlined,
          tint: NestTileTint.peach,
          size: NestSize.avatarMedium,
          iconSize: NestSize.iconMedium,
        ),
        trailing: onTap == null ? null : const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
      IdeaDinner(:final idea) => NestListRow(
        title: idea.name,
        subtitle:
            '$dayName · ${PlanWeekCopy.ingredientsLine(idea.ingredients.length)}'
            ' · ${idea.ingredients.map((line) => line.name).join(', ')}',
        leading: const NestIconTile(
          icon: Icons.auto_awesome_rounded,
          tint: NestTileTint.pink,
          size: NestSize.avatarMedium,
          iconSize: NestSize.iconMedium,
        ),
        footer: const NestTag(
          label: PlanWeekCopy.newIdeaCheck,
          tone: NestTagTone.warning,
          icon: Icons.info_outline_rounded,
        ),
        trailing: onTap == null ? null : const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    };
  }

  Future<void> _change(BuildContext context, String dayName) async {
    final controller = context.read<PlanWeekController>();
    final current = planned.dinners[day];
    final choice = await showPlanWeekDinnerSheet(
      context: context,
      dayName: dayName,
      library: controller.mealLibrary,
      current: current,
    );
    switch (choice) {
      case null:
        return;
      case DinnerKept():
        return;
      case DinnerMealChosen(:final meal):
        controller.setDinner(day, LibraryDinner(meal, PickOrigin.swapped));
      case DinnerLeftEmpty():
        controller.setDinner(day, null);
    }
  }

  static String _originWords(PickOrigin origin) => switch (origin) {
    PickOrigin.suggested => PlanWeekCopy.originSuggested,
    PickOrigin.filled => PlanWeekCopy.originFilled,
    PickOrigin.swapped => PlanWeekCopy.originSwapped,
  };
}
