import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../meal_planning/model/meal.dart';
import '../model/planned_week.dart';

/// What the dinner sheet came back with. Closing it is null — no change.
sealed class DinnerChoice {
  const DinnerChoice();
}

final class DinnerKept extends DinnerChoice {
  const DinnerKept();
}

final class DinnerMealChosen extends DinnerChoice {
  const DinnerMealChosen(this.meal);
  final Meal meal;
}

final class DinnerLeftEmpty extends DinnerChoice {
  const DinnerLeftEmpty();
}

/// Changing one planned dinner: keep a new idea, pick one of the family's own
/// meals, or leave the night empty.
Future<DinnerChoice?> showPlanWeekDinnerSheet({
  required BuildContext context,
  required String dayName,
  required List<Meal> library,
  required PlannedDinner? current,
}) => showNestSheet<DinnerChoice>(
  context: context,
  title: PlanWeekCopy.dinnerSheetTitle(dayName),
  builder: (_) => _DinnerSheetBody(library: library, current: current),
);

class _DinnerSheetBody extends StatelessWidget {
  const _DinnerSheetBody({required this.library, required this.current});

  final List<Meal> library;
  final PlannedDinner? current;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final chosenId = switch (current) {
      LibraryDinner(:final meal) => meal.id,
      _ => null,
    };
    final sorted = [...library]..sort((a, b) => a.nameKey.compareTo(b.nameKey));
    void pop(DinnerChoice choice) => Navigator.of(context).pop(choice);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: NestSize.pagesHeight),
      child: ListView(
        shrinkWrap: true,
        children: [
          if (current case IdeaDinner(:final idea))
            NestListRow(
              title: PlanWeekCopy.keepIdea,
              subtitle: idea.name,
              leading: const NestIconTile(
                icon: Icons.auto_awesome_rounded,
                tint: NestTileTint.pink,
                size: NestSize.avatarMedium,
                iconSize: NestSize.iconMedium,
              ),
              isSelected: true,
              onTap: () => pop(const DinnerKept()),
            ),
          const SizedBox(height: NestSpace.sm),
          Text(PlanWeekCopy.fromYourMeals, style: nest.text.caption),
          if (sorted.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: NestSpace.sm),
              child: Text(PlanWeekCopy.noMeals, style: nest.text.bodySecondary),
            ),
          for (final meal in sorted)
            NestListRow(
              key: ValueKey('plan-dinner-meal-${meal.id}'),
              title: meal.name,
              isSelected: meal.id == chosenId,
              onTap: () => pop(DinnerMealChosen(meal)),
            ),
          const SizedBox(height: NestSpace.sm),
          NestListRow(
            title: PlanWeekCopy.leaveEmpty,
            leading: const Icon(Icons.remove_circle_outline_rounded),
            onTap: () => pop(const DinnerLeftEmpty()),
          ),
        ],
      ),
    );
  }
}
