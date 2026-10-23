import 'package:flutter/foundation.dart';

import '../../../shared/time/calendar_date.dart';
import 'lunch_auto_fill.dart';
import 'lunch_board.dart';
import 'lunch_pick.dart';
import 'lunch_plan.dart';
import 'lunch_slot.dart';

/// Where one compartment's pick in the review comes from.
sealed class FillWeekSource {
  const FillWeekSource();
}

/// Somebody packed it already; the fill leaves it alone.
final class FillWeekPacked extends FillWeekSource {
  const FillWeekPacked();
}

/// A box — chosen, or a go-to box in rotation — put it there.
final class FillWeekFromBox extends FillWeekSource {
  const FillWeekFromBox(this.boxName);

  final String boxName;
}

/// NestPrep chose it from what the child eats.
final class FillWeekByNestPrep extends FillWeekSource {
  const FillWeekByNestPrep();
}

/// One compartment of one day in the review.
typedef FillWeekSlot = ({
  LunchSlot slot,
  LunchPick pick,
  FillWeekSource source,
});

/// One school day in *Fill the week*'s review (lunch-box ADR-0020): what
/// is in each compartment once the fill is written and where each came from,
/// or that the day has gone and is left as it is.
@immutable
final class FillWeekDay {
  FillWeekDay({
    required this.date,
    required this.hasGone,
    required List<FillWeekSlot> slots,
  }) : slots = List.unmodifiable(slots);

  final CalendarDate date;
  final bool hasGone;
  final List<FillWeekSlot> slots;

  /// The fill adds something to this day.
  bool get gainsSomething =>
      slots.any((slot) => slot.source is! FillWeekPacked);
}

/// The whole week a fill would leave one child with, day by day, before
/// anything is written — what the review step shows.
@immutable
final class FillWeekPreview {
  FillWeekPreview({required List<FillWeekDay> days, required this.result})
    : days = List.unmodifiable(days);

  factory FillWeekPreview.of(
    LunchChildWeek childWeek,
    LunchAutoFillResult result,
  ) => FillWeekPreview(
    result: result,
    days: [
      for (final day in childWeek.days)
        FillWeekDay(
          date: day.date,
          hasGone: day.hasHappened,
          slots: [
            for (final slot in LunchSlot.values)
              ?_slotOf(day.date.weekday, slot, day.box[slot], result),
          ],
        ),
    ],
  );

  final List<FillWeekDay> days;
  final LunchAutoFillResult result;

  /// How many compartments the fill adds.
  int get added => result.picks.length;

  bool get isEmpty => result.isEmpty;

  /// Every school day of the week has gone, so there is nothing to fill.
  bool get hasNoDaysLeft => days.every((day) => day.hasGone);

  static FillWeekSlot? _slotOf(
    int weekday,
    LunchSlot slot,
    LunchPick? packed,
    LunchAutoFillResult result,
  ) {
    if (packed != null) {
      return (slot: slot, pick: packed, source: const FillWeekPacked());
    }
    final key = LunchPlan.slotKey(weekday, slot);
    final pick = result.picks[key];
    if (pick == null) return null;
    return (
      slot: slot,
      pick: pick,
      source: switch (result.packedFromBox[key]) {
        final boxName? => FillWeekFromBox(boxName),
        null => const FillWeekByNestPrep(),
      },
    );
  }
}
