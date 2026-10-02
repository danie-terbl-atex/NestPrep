import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/kid_copy.dart';
import '../../meal_planning/model/meal.dart';
import '../../meal_planning/model/week_plan.dart';

/// What the household is eating today, as a kid reads it: three meals, each
/// with its own picture and its name, or an honest "not planned yet"
/// (accounts ADR-0003). Read-only — the plan is the grown-ups' to change.
class KidFoodCard extends StatelessWidget {
  const KidFoodCard({required this.meals, super.key});

  final Map<MealSlot, Meal?> meals;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return NestCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(KidCopy.foodTitle, style: nest.text.title),
          const SizedBox(height: NestSpace.md),
          for (final slot in MealSlot.values) ...[
            if (slot != MealSlot.values.first)
              const SizedBox(height: NestSpace.sm),
            _MealRow(slot: slot, meal: meals[slot]),
          ],
        ],
      ),
    );
  }
}

class _MealRow extends StatelessWidget {
  const _MealRow({required this.slot, required this.meal});

  final MealSlot slot;
  final Meal? meal;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final (icon, tint) = switch (slot) {
      MealSlot.breakfast => (Icons.free_breakfast_rounded, NestTileTint.butter),
      MealSlot.lunch => (Icons.lunch_dining_rounded, NestTileTint.basil),
      MealSlot.dinner => (Icons.dinner_dining_rounded, NestTileTint.lilac),
    };
    final name = meal?.name;
    return Row(
      children: [
        NestIconTile(icon: icon, tint: tint),
        const SizedBox(width: NestSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppCopy.mealSlotName(slot.name),
                style: nest.text.label.copyWith(
                  color: nest.colors.inkSecondary,
                ),
              ),
              Text(
                name ?? KidCopy.foodNothingPlanned,
                style: name == null
                    ? nest.text.body.copyWith(color: nest.colors.inkTertiary)
                    : nest.text.bodyStrong,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
