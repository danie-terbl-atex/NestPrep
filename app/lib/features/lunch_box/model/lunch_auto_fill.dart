import 'package:flutter/foundation.dart';

import '../../../shared/time/calendar_date.dart';
import '../../family_profiles/model/food_rules.dart';
import 'lunch_favourite.dart';
import 'lunch_fill_bias.dart';
import 'lunch_fill_choice.dart';
import 'lunch_item.dart';
import 'lunch_pick.dart';
import 'lunch_plan.dart';
import 'lunch_safety.dart';
import 'lunch_slot.dart';
import 'lunch_suggestions.dart';
import 'lunch_taste.dart';
import 'lunch_week.dart';

/// What filling a week wrote, and how much of it came from boxes.
@immutable
class LunchAutoFillResult {
  LunchAutoFillResult({
    required Map<String, LunchPick> picks,
    required List<int> favouriteDays,
    Map<String, String> packedFromBox = const {},
  }) : picks = Map.unmodifiable(picks),
       favouriteDays = List.unmodifiable(favouriteDays),
       packedFromBox = Map.unmodifiable(packedFromBox);

  /// Slot key → what goes in it. Only slots that were empty.
  final Map<String, LunchPick> picks;

  /// Weekdays packed from a go-to box in rotation, Monday first.
  final List<int> favouriteDays;

  /// Slot key → the name of the box its pick came from — a go-to box in
  /// rotation, or a box the parent chose. A key in [picks] and not here is
  /// one NestPrep chose from what the child eats.
  final Map<String, String> packedFromBox;

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
///
/// A [LunchFillBias] — planning from the pantry (lunch-box ADR-0006) — may
/// skip a go-to box and choose among a slot's suggestions. A
/// [LunchFillChoice] — *Fill the week*'s flow (ADR-0020) — leaves every day
/// that has gone, and, when the parent chose boxes, puts those on the empty
/// days in turn instead of step 1's go-to boxes. Without either this is
/// exactly ADR-0003's fill.
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
    LunchFillBias? bias,
    LunchFillChoice? choice,
  }) {
    final run = _Run(
      plan: plan,
      library: library,
      rules: rules,
      taste: taste,
      bias: bias,
    );
    final days = [
      for (final day in week.schoolDays)
        if (choice?.isOpen(day) ?? true) day.weekday,
    ];
    if (choice == null || choice.isSkipped) {
      _packFavourites(run, days, rotationFor(week, run.safeOwn(favourites)));
    } else {
      _packChosen(run, days, choice);
    }
    _packSuggestions(run, days);
    return LunchAutoFillResult(
      picks: run.picks,
      favouriteDays: run.favouriteDays,
      packedFromBox: run.fromBox,
    );
  }

  /// Step 1: the child's safe go-to boxes, in [rotation], one per empty day.
  static void _packFavourites(
    _Run run,
    List<int> days,
    List<LunchFavourite> rotation,
  ) {
    final bias = run.bias;
    final safe = [...rotation];
    for (final day in days) {
      if (safe.isEmpty) break;
      if (!run.plan.boxOn(day).isEmpty) continue;
      final index = bias == null
          ? 0
          : safe.indexWhere((f) => bias.acceptsFavourite(f, run.added));
      // What a bias turns down now it turns down later too: a fill only
      // ever takes more.
      if (index < 0) break;
      final favourite = safe.removeAt(index);
      for (final (slot, pick) in favourite.box.filled) {
        run.put(LunchPlan.slotKey(day, slot), run.fresh(pick), favourite.name);
      }
      run.favouriteDays.add(day);
    }
  }

  /// The boxes the parent chose, on the empty open days in turn — the first
  /// on the first such day, the next on the next, round again.
  static void _packChosen(_Run run, List<int> days, LunchFillChoice choice) {
    var turn = 0;
    for (final day in days) {
      if (!run.plan.boxOn(day).isEmpty) continue;
      final box = choice.boxes[turn++ % choice.boxes.length];
      for (final MapEntry(key: slot, value: pick) in box.packsOn(day).entries) {
        if (!run.isSafe(pick)) continue;
        run.put(LunchPlan.slotKey(day, slot), pick, box.name);
      }
    }
  }

  /// Step 2: the best suggestion in every slot still empty, a treat on
  /// Friday only.
  static void _packSuggestions(_Run run, List<int> days) {
    final bias = run.bias;
    for (final day in days) {
      for (final slot in LunchSlot.values) {
        final key = LunchPlan.slotKey(day, slot);
        if (run.isTaken(key) || !slot.isAutoFilledOn(day)) continue;
        final ranked = LunchSuggestions.rank(
          slot: slot,
          library: run.library,
          rules: run.rules,
          taste: run.taste,
          usesThisWeek: run.uses,
        );
        final best = bias == null
            ? ranked.best
            : bias.choose(ranked, run.added);
        if (best != null) run.put(key, LunchPick.of(best.item));
      }
    }
  }

  /// A child's favourites in the order this [week] uses them: the same list
  /// turned five places further on each week, so every favourite comes round
  /// and none is stuck on Monday.
  static List<LunchFavourite> rotationFor(
    LunchWeek week,
    List<LunchFavourite> inOrder,
  ) {
    if (inOrder.isEmpty) return [];
    final weekIndex = _firstMonday.daysUntil(week.monday) ~/ 7;
    final start = (weekIndex * LunchWeek.schoolDayCount) % inOrder.length;
    return [...inOrder.skip(start), ...inOrder.take(start)];
  }
}

/// One fill in progress: what it has put where, and how often each item is
/// in the week so far, so suggestions vary.
final class _Run {
  _Run({
    required this.plan,
    required this.library,
    required this.rules,
    required this.taste,
    required this.bias,
  }) : _itemsById = {for (final item in library) item.id: item} {
    for (final pick in plan.slots.values) {
      uses[pick.itemId] = (uses[pick.itemId] ?? 0) + 1;
    }
  }

  final LunchPlan plan;
  final List<LunchItem> library;
  final FoodRules rules;
  final LunchTaste taste;
  final LunchFillBias? bias;
  final Map<String, LunchItem> _itemsById;
  final picks = <String, LunchPick>{};
  final uses = <String, int>{};
  final added = <String, int>{};
  final favouriteDays = <int>[];
  final fromBox = <String, String>{};

  /// The child's own go-to boxes that are safe for them, in rotation order
  /// — by the library's items as they are now.
  List<LunchFavourite> safeOwn(List<LunchFavourite> favourites) => [
    for (final favourite in favourites)
      if (favourite.childId == plan.childId &&
          favourite.box.filled.every(
            (entry) => LunchSafety.isSafe(
              allergens: fresh(entry.$2).knownAllergens,
              rules: rules,
            ),
          ))
        favourite,
  ]..sort(LunchFavourite.inRotationOrder);

  bool isTaken(String key) =>
      plan.slots.containsKey(key) || picks.containsKey(key);

  /// The library's item as it is now, for a pick saved earlier.
  LunchPick fresh(LunchPick pick) => switch (_itemsById[pick.itemId]) {
    final item? => LunchPick.of(item),
    null => pick,
  };

  /// Safe by the pick's own codes and the library item's now, together.
  bool isSafe(LunchPick pick) => LunchSafety.isSafe(
    allergens: {...pick.knownAllergens, ...fresh(pick).knownAllergens},
    rules: rules,
  );

  void put(String key, LunchPick pick, [String? boxName]) {
    picks[key] = pick;
    if (boxName != null) fromBox[key] = boxName;
    uses[pick.itemId] = (uses[pick.itemId] ?? 0) + 1;
    added[pick.itemId] = (added[pick.itemId] ?? 0) + 1;
  }
}
