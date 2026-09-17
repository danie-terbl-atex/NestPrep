import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/time/calendar_date.dart';
import '../model/meal.dart';
import '../model/meal_week.dart';
import '../model/week_plan.dart';
import '../state/meal_plan_controller.dart';
import 'slot_picker_sheet.dart';

/// One day, with its three slots. An empty slot is a tap target that says it is
/// empty rather than a gap, so the week always reads as a grid (`FE-08`).
class PlannedDayCard extends StatelessWidget {
  const PlannedDayCard({
    required this.day,
    required this.today,
    required this.library,
    super.key,
  });

  final PlannedDay day;
  final CalendarDate today;
  final List<Meal> library;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final isToday = day.date == today;
    return NestCard(
      variant: isToday ? NestCardVariant.tinted : NestCardVariant.flat,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            NestDates.dayInARun(day.date, today),
            style: nest.text.bodyStrong.copyWith(
              color: isToday ? nest.colors.accentInk : nest.colors.ink,
            ),
          ),
          const SizedBox(height: NestSpace.sm),
          for (final slot in MealSlot.values)
            _SlotRow(
              date: day.date,
              slot: slot,
              meal: day.meals[slot],
              library: library,
            ),
        ],
      ),
    );
  }
}

class _SlotRow extends StatelessWidget {
  const _SlotRow({
    required this.date,
    required this.slot,
    required this.meal,
    required this.library,
  });

  final CalendarDate date;
  final MealSlot slot;
  final Meal? meal;
  final List<Meal> library;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final planned = meal;
    return InkWell(
      borderRadius: BorderRadius.circular(NestRadius.sm),
      onTap: () => _pick(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: NestSpace.sm),
        child: Row(
          children: [
            SizedBox(
              width: NestSize.avatarLarge + NestSpace.lg,
              child: Text(
                AppCopy.mealSlotName(slot.name),
                style: nest.text.caption.copyWith(
                  color: nest.colors.inkTertiary,
                ),
              ),
            ),
            Expanded(
              child: Text(
                planned?.name ?? AppCopy.mealsNothingPlanned,
                style: nest.text.body.copyWith(
                  color: planned == null
                      ? nest.colors.inkTertiary
                      : nest.colors.ink,
                  fontStyle: planned == null ? FontStyle.italic : null,
                ),
              ),
            ),
            Icon(
              planned == null ? Icons.add : Icons.chevron_right,
              size: NestSize.iconSmall,
              color: nest.colors.inkTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final controller = context.read<MealPlanController>();
    final choice = await showSlotPickerSheet(
      context: context,
      slot: slot,
      date: date,
      today: controller.today,
      library: library,
      current: meal,
    );
    final slotKey = WeekPlan.slotKey(date.weekday, slot);
    switch (choice) {
      case null:
        return;
      case SlotCleared():
        await controller.clearSlot(slotKey);
      case SlotPicked(:final mealId):
        await controller.setSlot(slotKey, mealId);
      case SlotTyped(:final name):
        await controller.setSlotByName(slotKey, name);
    }
  }
}
