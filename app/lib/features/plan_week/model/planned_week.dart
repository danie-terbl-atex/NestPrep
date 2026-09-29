import 'package:flutter/foundation.dart';

import '../../family_profiles/model/family_entry.dart';
import '../../lunch_box/model/lunch_item.dart';
import '../../lunch_box/model/lunch_pick.dart';
import '../../lunch_box/model/lunch_plan.dart';
import '../../lunch_box/model/lunch_slot.dart';
import '../../lunch_box/model/lunch_week.dart';
import '../../meal_planning/model/meal.dart';
import 'dinner_idea.dart';

/// Who made the plan (lunch-box ADR-0011): the model, or — when AI is off,
/// spent or not answering — the app's own auto-fill and a dinner rotation,
/// said so on the review.
enum PlanSource { ai, fallback }

/// Why a plan was made without AI.
enum PlanFallbackReason { aiOff, aiLimitReached, aiUnavailable, offline }

/// Where one proposed compartment came from, for the review to say.
enum PickOrigin {
  /// The model chose it.
  suggested,

  /// Auto-fill chose it (lunch-box ADR-0003): a plan without AI, or a gap the
  /// model left.
  filled,

  /// A parent swapped it on the review.
  swapped,
}

@immutable
final class PlannedPick {
  const PlannedPick(this.item, this.origin);

  final LunchItem item;
  final PickOrigin origin;
}

/// One child's week on the review: what is packed already, untouched, and
/// what the plan adds to the empty compartments.
@immutable
final class PlannedChildWeek {
  PlannedChildWeek({
    required this.child,
    required this.existing,
    required Map<String, PlannedPick> added,
  }) : added = Map.unmodifiable(added);

  final FamilyEntry child;

  /// This week's plan as stored: never replaced by a plan (lunch-box
  /// ADR-0003's rule, kept).
  final LunchPlan existing;

  /// Slot key → what the plan puts there.
  final Map<String, PlannedPick> added;

  String get childId => child.memberId;

  LunchPick? existingAt(int day, LunchSlot slot) => existing.pickAt(day, slot);

  PlannedPick? addedAt(int day, LunchSlot slot) =>
      added[LunchPlan.slotKey(day, slot)];
}

/// One dinner the plan puts on the week.
sealed class PlannedDinner {
  const PlannedDinner();
}

/// A meal the household already has.
final class LibraryDinner extends PlannedDinner {
  const LibraryDinner(this.meal, this.origin);

  final Meal meal;
  final PickOrigin origin;
}

/// Something new, with what it needs — checked against everybody's
/// allergies by its words on the server, and said to be checked on the
/// review.
final class IdeaDinner extends PlannedDinner {
  const IdeaDinner(this.idea);

  final DinnerIdea idea;
}

/// The whole proposal the review shows and edits (lunch-box ADR-0011).
/// Nothing in it is written until the parent uses it.
@immutable
final class PlannedWeek {
  PlannedWeek({
    required this.week,
    required this.source,
    required List<PlannedChildWeek> children,
    required this.dinnersIncluded,
    required Map<int, PlannedDinner> dinners,
    required Map<int, Meal> existingDinners,
    this.fallbackReason,
    this.callsLeft,
    this.dropped = 0,
  }) : children = List.unmodifiable(children),
       dinners = Map.unmodifiable(dinners),
       existingDinners = Map.unmodifiable(existingDinners);

  final LunchWeek week;
  final PlanSource source;
  final PlanFallbackReason? fallbackReason;
  final int? callsLeft;

  /// What the server left out as not allowed.
  final int dropped;
  final List<PlannedChildWeek> children;
  final bool dinnersIncluded;

  /// Weekday → the dinner the plan adds.
  final Map<int, PlannedDinner> dinners;

  /// Weekday → the dinner already planned, untouched.
  final Map<int, Meal> existingDinners;

  int get lunchCount =>
      children.fold(0, (total, child) => total + child.added.length);

  int get ideaCount => dinners.values.whereType<IdeaDinner>().length;

  bool get isEmpty => lunchCount == 0 && dinners.isEmpty;

  /// Every ingredient line of the new ideas, for the grocery list.
  List<IdeaIngredient> get ideaIngredients => [
    for (final dinner in dinners.values.whereType<IdeaDinner>())
      ...dinner.idea.ingredients,
  ];

  PlannedWeek withLunch(String childId, String key, PlannedPick? pick) => _copy(
    children: [
      for (final child in children)
        if (child.childId == childId)
          PlannedChildWeek(
            child: child.child,
            existing: child.existing,
            added: {
              for (final entry in child.added.entries)
                if (entry.key != key) entry.key: entry.value,
              key: ?pick,
            },
          )
        else
          child,
    ],
  );

  PlannedWeek withDinner(int day, PlannedDinner? dinner) => _copy(
    dinners: {
      for (final entry in dinners.entries)
        if (entry.key != day) entry.key: entry.value,
      day: ?dinner,
    },
  );

  PlannedWeek _copy({
    List<PlannedChildWeek>? children,
    Map<int, PlannedDinner>? dinners,
  }) => PlannedWeek(
    week: week,
    source: source,
    fallbackReason: fallbackReason,
    callsLeft: callsLeft,
    dropped: dropped,
    children: children ?? this.children,
    dinnersIncluded: dinnersIncluded,
    dinners: dinners ?? this.dinners,
    existingDinners: existingDinners,
  );
}
