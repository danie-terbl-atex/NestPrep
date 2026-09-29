import 'package:flutter/foundation.dart';

import 'lunch_feedback.dart';
import 'lunch_plan.dart';
import 'lunch_slot.dart';
import 'lunch_week.dart';

/// What one child's history says about one item: how often it came home
/// eaten and how often not, and the score that ranks it (lunch-box ADR-0003).
@immutable
class ItemTaste {
  const ItemTaste({this.eaten = 0, this.left = 0, this.score = 0});

  static const unknown = ItemTaste();

  final int eaten;
  final int left;
  final double score;

  ItemTaste add(LunchVerdict verdict, {required double weight}) =>
      switch (verdict) {
        LunchVerdict.ate => ItemTaste(
          eaten: eaten + 1,
          left: left,
          score: score + weight,
        ),
        LunchVerdict.left => ItemTaste(
          eaten: eaten,
          left: left + 1,
          score: score - weight,
        ),
      };
}

/// The learning, in full — a transparent, deterministic tally rather than a
/// model (lunch-box ADR-0003):
///
/// - a thing marked **eaten on its own** scores +2, **eaten with the box** +1;
/// - **left on its own** −3, **left with the box** −1 (a box sent back may be
///   one thing's fault, so the box's verdict counts for less than an item's,
///   and leaving counts for more than eating, because a parent notices waste);
/// - marks from the last four weeks count in full, from the four before that
///   at half, and older marks not at all — tastes change.
///
/// Nothing else moves a score here. Likes, dislikes and variety are applied
/// where suggestions are ranked (`LunchSuggestions`).
@immutable
class LunchTaste {
  const LunchTaste._(this._byItem);

  factory LunchTaste.from({
    required Iterable<LunchPlan> history,
    required LunchWeek current,
  }) {
    final byItem = <String, ItemTaste>{};
    for (final plan in history) {
      final LunchWeek week;
      try {
        week = plan.lunchWeek;
      } on FormatException {
        // A plan whose week this build cannot read teaches nothing; the plan
        // itself still shows (`BE-10`).
        continue;
      }
      final weeksAgo = week.weeksUntil(current);
      final recency = recencyWeight(weeksAgo);
      if (recency == 0) continue;
      for (final MapEntry(:key, :value) in plan.feedback.entries) {
        final day = int.tryParse(key);
        if (day == null) continue;
        for (final slot in LunchSlot.values) {
          final pick = plan.pickAt(day, slot);
          final verdict = value.verdictFor(slot);
          if (pick == null || verdict == null) continue;
          final points = pointsFor(
            verdict,
            onItsOwn: value.isMarkedOnItsOwn(slot),
          );
          byItem[pick.itemId] = (byItem[pick.itemId] ?? ItemTaste.unknown).add(
            verdict,
            weight: points * recency,
          );
        }
      }
    }
    return LunchTaste._(Map.unmodifiable(byItem));
  }

  static const nothingYet = LunchTaste._({});

  final Map<String, ItemTaste> _byItem;

  ItemTaste of(String itemId) => _byItem[itemId] ?? ItemTaste.unknown;

  bool get isEmpty => _byItem.isEmpty;

  /// The size of one mark before recency: see the class comment.
  static double pointsFor(LunchVerdict verdict, {required bool onItsOwn}) =>
      switch ((verdict, onItsOwn)) {
        (LunchVerdict.ate, true) => 2,
        (LunchVerdict.ate, false) => 1,
        (LunchVerdict.left, true) => 3,
        (LunchVerdict.left, false) => 1,
      };

  /// Full for the last four weeks, half for the four before, nothing older —
  /// and nothing from a week that has not happened.
  static double recencyWeight(int weeksAgo) {
    if (weeksAgo < 0) return 0;
    if (weeksAgo < LunchWeek.historyWeeks ~/ 2) return 1;
    if (weeksAgo <= LunchWeek.historyWeeks) return 0.5;
    return 0;
  }
}
