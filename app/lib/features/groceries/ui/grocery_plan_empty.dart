import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/grocery_plan_copy.dart';

/// The week's plans say nothing yet: what would make them, and the two ways
/// there (`FE-08` — an empty state says what to do next). Laid out in place,
/// not as a scroll view, because it sits inside the sheet's own list.
class GroceryPlanEmpty extends StatelessWidget {
  const GroceryPlanEmpty({
    required this.onPlanMeals,
    required this.onPlanLunches,
    super.key,
  });

  final VoidCallback onPlanMeals;
  final VoidCallback onPlanLunches;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: NestSpace.xl),
      child: Column(
        children: [
          const NestIconTile(
            icon: Icons.restaurant_menu_rounded,
            tint: NestTileTint.butter,
            size: NestSize.avatarLarge,
          ),
          const SizedBox(height: NestSpace.lg),
          Text(
            GroceryPlanCopy.emptyTitle,
            style: nest.text.title,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: NestSpace.sm),
          Text(
            GroceryPlanCopy.emptyBody,
            style: nest.text.bodySecondary,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: NestSpace.xl),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: NestSpace.sm,
            runSpacing: NestSpace.sm,
            children: [
              NestButton(
                label: GroceryPlanCopy.planMeals,
                icon: Icons.restaurant_outlined,
                variant: NestButtonVariant.tonal,
                size: NestButtonSize.small,
                isExpanded: false,
                onPressed: onPlanMeals,
              ),
              NestButton(
                label: GroceryPlanCopy.planLunches,
                icon: Icons.lunch_dining_outlined,
                variant: NestButtonVariant.tonal,
                size: NestButtonSize.small,
                isExpanded: false,
                onPressed: onPlanLunches,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
