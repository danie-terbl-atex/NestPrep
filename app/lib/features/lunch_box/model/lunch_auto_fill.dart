import 'package:flutter/foundation.dart';

import '../../../shared/time/calendar_date.dart';
import '../../family_profiles/model/food_rules.dart';
import 'lunch_favourite.dart';
import 'lunch_item.dart';
import 'lunch_pick.dart';
import 'lunch_plan.dart';
import 'lunch_safety.dart';
import 'lunch_slot.dart';
import 'lunch_suggestions.dart';
import 'lunch_taste.dart';
import 'lunch_week.dart';

/// What filling a week wrote, and how much of it came from favourites.
@immutable
class LunchAutoFillResult {
  const LunchAutoFillResult({required this.picks, required this.favouriteDays});

  /// Slot key → what goes in it. Only slots that were empty.
  final Map<String, LunchPick> picks;

  /// Weekdays packed from a favourite, Monday first.
  final List<int> favouriteDays;

  bool get isEmpty => picks.isEmpty;

  /// How many days gained something.
  int get dayCount =>
      {for (final key in picks.keys) key.substring(0, key.indexOf('_'))}.length;
}

/// Fills the empty parts of one child's week (lunch-box ADR-0003):
///
/// 1. Every **completely empty** school day takes one of the child's safe
///    favourites, each at most once a week. Where the week starts in the
///    child's favourites **rotates** with the week, five places on each time,
///    so every favourite comes round and none is stuck on Monday.
/// 2. Every slot still empty takes the best suggestion for it
///    (`LunchSuggestions`), counting what the week already holds so it varies
///    — a treat on Friday only.
///
/// It never replaces something a person put in a box: a filled slot is
/// locked by being filled. Deterministic: the same inputs pack the same week.
abstract final class LunchAutoFill {
  /// Monday 5 January 1970, from which a week's place in the rotation counts.
  static final _firstMonday = CalendarDate(1970, 1, 5);

  static LunchAutoFillResult fill({
    required LunchPlan plan,
    required LunchWeek week,
    required List<LunchFavourite> favourites,
    required List<LunchItem> library,
    required FoodRules rules,
    required LunchTaste taste,
  }) {
    final itemsById = {for (final item in library) item.id: item};
    final picks = <String, LunchPick>{};
    final uses = _usesIn(plan);

    LunchPick fresh(LunchPick pick) {
      final item = itemsById[pick.itemId];
      return item == null ? pick : LunchPick.of(item);
    }

    void put(String key, LunchPick pick) {
      picks[key] = pick;
      uses[pick.itemId] = (uses[pick.itemId] ?? 0) + 1;
    }

    final rotation = rotationFor(
      week,
      [
        for (final favourite in favourites)
          if (favourite.childId == plan.childId &&
              _isSafe(favourite, rules, fresh))
            favourite,
      ]..sort(LunchFavourite.inRotationOrder),
    );
    final favouriteDays = <int>[];
    for (final day in week.schoolDays) {
      if (rotation.isEmpty) break;
      if (!plan.boxOn(day.weekday).isEmpty) continue;
      final favourite = rotation.removeAt(0);
      for (final (slot, pick) in favourite.box.filled) {
        put(LunchPlan.slotKey(day.weekday, slot), fresh(pick));
      }
      favouriteDays.add(day.weekday);
    }

    for (final day in week.schoolDays) {
      for (final slot in LunchSlot.values) {
        final key = LunchPlan.slotKey(day.weekday, slot);
        if (plan.slots.containsKey(key) || picks.containsKey(key)) continue;
        if (!slot.isAutoFilledOn(day.weekday)) continue;
        final best = LunchSuggestions.rank(
          slot: slot,
          library: library,
          rules: rules,
          taste: taste,
          usesThisWeek: uses,
        ).best;
        if (best != null) put(key, LunchPick.of(best.item));
      }
    }
    return LunchAutoFillResult(picks: picks, favouriteDays: favouriteDays);
  }

  /// A child's favourites in the order this [week] uses them: the same list
  /// turned five places further on each week.
  static List<LunchFavourite> rotationFor(
    LunchWeek week,
    List<LunchFavourite> inOrder,
  ) {
    if (inOrder.isEmpty) return [];
    final weekIndex = _firstMonday.daysUntil(week.monday) ~/ 7;
    final start = (weekIndex * LunchWeek.schoolDayCount) % inOrder.length;
    return [...inOrder.skip(start), ...inOrder.take(start)];
  }

  static bool _isSafe(
    LunchFavourite favourite,
    FoodRules rules,
    LunchPick Function(LunchPick) fresh,
  ) => favourite.box.filled.every(
    (entry) => LunchSafety.isSafe(
      allergens: fresh(entry.$2).knownAllergens,
      rules: rules,
    ),
  );

  static Map<String, int> _usesIn(LunchPlan plan) {
    final uses = <String, int>{};
    for (final pick in plan.slots.values) {
      uses[pick.itemId] = (uses[pick.itemId] ?? 0) + 1;
    }
    return uses;
  }
}
