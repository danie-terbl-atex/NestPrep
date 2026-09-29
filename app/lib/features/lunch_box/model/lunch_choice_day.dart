import 'package:flutter/foundation.dart';

import '../../../shared/time/calendar_date.dart';
import 'lunch_choices.dart';
import 'lunch_pick.dart';
import 'lunch_plan.dart';
import 'lunch_slot.dart';
import 'lunch_week.dart';

/// One compartment a child is choosing for: the options a parent approved,
/// and what is in the box now.
@immutable
class LunchChoiceSlot {
  LunchChoiceSlot({
    required this.slot,
    required List<LunchPick> options,
    required this.current,
  }) : options = List.unmodifiable(options);

  final LunchSlot slot;
  final List<LunchPick> options;

  /// What the plan holds in this compartment now, whoever put it there.
  final LunchPick? current;

  /// The option the box holds, if it holds one of them.
  LunchPick? get chosen =>
      options.where((option) => option.itemId == current?.itemId).firstOrNull;

  bool get isChosen => chosen != null;
}

/// One school day a child can still choose for (lunch-box ADR-0008): the
/// compartments with options, in packing order. What both the kid's own
/// chooser and a parent's *let them choose* show.
@immutable
class LunchChoiceDay {
  LunchChoiceDay({required this.date, required List<LunchChoiceSlot> slots})
    : slots = List.unmodifiable(slots);

  final CalendarDate date;
  final List<LunchChoiceSlot> slots;

  bool get isComplete => slots.every((slot) => slot.isChosen);

  int get chosenCount => slots.where((slot) => slot.isChosen).length;

  /// Today and the school days after it that have anything to choose —
  /// days gone by are not offered.
  static List<LunchChoiceDay> ahead({
    required LunchChoices choices,
    required LunchPlan plan,
    required LunchWeek week,
    required CalendarDate today,
  }) => [
    for (final date in week.schoolDays)
      if (!date.isBefore(today) && choices.hasOptionsOn(date.weekday))
        LunchChoiceDay(
          date: date,
          slots: [
            for (final slot in LunchSlot.values)
              if (choices.optionsAt(date.weekday, slot).isNotEmpty)
                LunchChoiceSlot(
                  slot: slot,
                  options: choices.optionsAt(date.weekday, slot),
                  current: plan.pickAt(date.weekday, slot),
                ),
          ],
        ),
  ];
}
