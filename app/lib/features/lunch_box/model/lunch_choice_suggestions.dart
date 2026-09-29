import '../../../shared/time/calendar_date.dart';
import 'lunch_board.dart';
import 'lunch_choices.dart';
import 'lunch_pick.dart';
import 'lunch_plan.dart';
import 'lunch_slot.dart';
import 'lunch_suggestions.dart';

/// *Suggest options* for a child's week (lunch-box ADR-0008): for every
/// compartment from today on that is empty in the plan and has no options
/// yet, the child's top three suggestions — safe and not disliked, so the
/// rules would never refuse one — with a treat on Friday only, as auto-fill
/// packs it (lunch-box ADR-0003).
///
/// Each option offered counts as a use of that item this week, so Monday's
/// three are not Tuesday's three. A compartment with fewer than two
/// suggestions is left alone: one thing is not a choice.
abstract final class LunchChoiceSuggestions {
  static Map<int, Map<String, List<LunchPick>>> forWeek({
    required LunchBoard board,
    required LunchChildWeek childWeek,
    required LunchChoices choices,
    required CalendarDate today,
  }) {
    final uses = <String, int>{};
    for (final pick in childWeek.plan.slots.values) {
      uses[pick.itemId] = (uses[pick.itemId] ?? 0) + 1;
    }
    for (final options in choices.options.values) {
      for (final option in options) {
        uses[option.itemId] = (uses[option.itemId] ?? 0) + 1;
      }
    }
    final byDay = <int, Map<String, List<LunchPick>>>{};
    for (final date in board.week.schoolDays) {
      if (date.isBefore(today)) continue;
      final day = <String, List<LunchPick>>{};
      for (final slot in LunchSlot.values) {
        if (!slot.isAutoFilledOn(date.weekday)) continue;
        if (childWeek.plan.pickAt(date.weekday, slot) != null) continue;
        if (choices.optionsAt(date.weekday, slot).isNotEmpty) continue;
        final ranked = LunchSuggestions.rank(
          slot: slot,
          library: board.library,
          rules: childWeek.child.foodRules,
          taste: childWeek.taste,
          usesThisWeek: uses,
        );
        final top = ranked.suggested.take(LunchChoices.mostOptions).toList();
        if (top.length < LunchChoices.fewestOptions) continue;
        day[LunchPlan.slotKey(date.weekday, slot)] = [
          for (final entry in top) LunchPick.of(entry.item),
        ];
        for (final entry in top) {
          uses[entry.item.id] = (uses[entry.item.id] ?? 0) + 1;
        }
      }
      if (day.isNotEmpty) byDay[date.weekday] = day;
    }
    return byDay;
  }
}
