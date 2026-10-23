import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/time/calendar_date.dart';
import '../../meal_planning/model/week_plan.dart';
import '../model/recipe.dart';
import '../model/recipe_context.dart';

/// Where on the week a recipe goes: a day and one of its three meals.
@immutable
final class WeekSlotChoice {
  const WeekSlotChoice({required this.day, required this.slot});

  final CalendarDate day;
  final MealSlot slot;
}

/// *Add to this week* (recipes ADR-0003 §6): this week or next, a day from
/// today on, and breakfast, lunch or dinner — the meal the recipe is for
/// chosen already — for the number of people the page is cooking for. It
/// closes with the choice; the page writes it, so a second tap has nothing
/// to press (`FE-10`).
Future<WeekSlotChoice?> showAddToWeekSheet({
  required BuildContext context,
  required Recipe recipe,
  required int people,
  required CalendarDate today,
}) => showNestSheet<WeekSlotChoice>(
  context: context,
  title: RecipeCopy.addSheetTitle,
  builder: (_) => AddToWeekSheet(recipe: recipe, people: people, today: today),
);

class AddToWeekSheet extends StatefulWidget {
  const AddToWeekSheet({
    required this.recipe,
    required this.people,
    required this.today,
    super.key,
  });

  final Recipe recipe;
  final int people;
  final CalendarDate today;

  /// The meal a recipe for [context] fills; dinner for one the meal plan has
  /// no meal for.
  static MealSlot slotFor(RecipeContext? context) => switch (context) {
    RecipeContext.breakfast => MealSlot.breakfast,
    RecipeContext.lunch => MealSlot.lunch,
    _ => MealSlot.dinner,
  };

  @override
  State<AddToWeekSheet> createState() => _AddToWeekSheetState();
}

class _AddToWeekSheetState extends State<AddToWeekSheet> {
  var _isNextWeek = false;
  late var _day = widget.today;
  late var _slot = AddToWeekSheet.slotFor(widget.recipe.firstMeal);

  /// This week from today, or all of next week: a day already gone is not
  /// one to plan.
  List<CalendarDate> get _days {
    final monday = widget.today.weekStart.addDays(_isNextWeek ? 7 : 0);
    return [
      for (var offset = 0; offset < WeekPlan.daysInAWeek; offset++)
        if (!monday.addDays(offset).isBefore(widget.today))
          monday.addDays(offset),
    ];
  }

  void _chooseWeek(bool isNextWeek) => setState(() {
    _isNextWeek = isNextWeek;
    _day = _days.first;
  });

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final label = nest.text.label.copyWith(color: nest.colors.inkSecondary);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.recipe.name, style: nest.text.bodyStrong),
          const SizedBox(height: NestSpace.xxs),
          Row(
            children: [
              Icon(
                LucideIcons.users,
                size: NestSize.iconSmall,
                color: nest.colors.inkSecondary,
              ),
              const SizedBox(width: NestSpace.xs),
              Expanded(
                child: Text(
                  RecipeCopy.forPeople(widget.people),
                  style: nest.text.bodySecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: NestSpace.xl),
          NestSegmentedControl<bool>(
            segments: const [
              NestSegment(value: false, label: RecipeCopy.thisWeek),
              NestSegment(value: true, label: RecipeCopy.nextWeek),
            ],
            selected: _isNextWeek,
            onSelect: _chooseWeek,
          ),
          const SizedBox(height: NestSpace.xl),
          Text(RecipeCopy.dayLabel, style: label),
          const SizedBox(height: NestSpace.sm),
          Wrap(
            spacing: NestSpace.sm,
            runSpacing: NestSpace.sm,
            children: [
              for (final day in _days)
                NestChip(
                  key: ValueKey(day.iso),
                  label: NestDates.full(day, widget.today),
                  semanticLabel: NestDates.relative(day, widget.today),
                  isSelected: day == _day,
                  onTap: () => setState(() => _day = day),
                ),
            ],
          ),
          const SizedBox(height: NestSpace.xl),
          Text(RecipeCopy.mealLabel, style: label),
          const SizedBox(height: NestSpace.sm),
          Wrap(
            spacing: NestSpace.sm,
            runSpacing: NestSpace.sm,
            children: [
              for (final slot in MealSlot.values)
                NestChip(
                  label: AppCopy.mealSlotName(slot.name),
                  isSelected: slot == _slot,
                  onTap: () => setState(() => _slot = slot),
                ),
            ],
          ),
          const SizedBox(height: NestSpace.xxl),
          NestButton(
            label: RecipeCopy.addTo(
              NestDates.weekdayName(_day),
              AppCopy.mealSlotName(_slot.name),
            ),
            icon: LucideIcons.calendarPlus,
            onPressed: () =>
                Navigator.of(context)
                    .pop(WeekSlotChoice(day: _day, slot: _slot)),
          ),
        ],
      ),
    );
  }
}
