import 'package:flutter/foundation.dart';

import '../../../shared/time/calendar_date.dart';
import '../../family_profiles/model/family_entry.dart';
import '../../family_profiles/model/family_roster.dart';
import 'lunch_day.dart';
import 'lunch_favourite.dart';
import 'lunch_item.dart';
import 'lunch_plan.dart';
import 'lunch_safety.dart';
import 'lunch_slot.dart';
import 'lunch_suggestions.dart';
import 'lunch_taste.dart';
import 'lunch_week.dart';

/// One child's week on the board: their plan, what their history has taught,
/// their go-to boxes, and five days already checked against their rules.
@immutable
class LunchChildWeek {
  LunchChildWeek({
    required this.child,
    required this.plan,
    required this.taste,
    required List<LunchFavourite> favourites,
    required this.days,
    Set<String> unsafeFavouriteIds = const {},
  }) : favourites = List.unmodifiable(favourites),
       unsafeFavouriteIds = Set.unmodifiable(unsafeFavouriteIds);

  factory LunchChildWeek.of({
    required FamilyEntry child,
    required LunchWeek week,
    required CalendarDate today,
    required LunchPlan plan,
    required List<LunchPlan> history,
    required List<LunchFavourite> favourites,
    required Map<String, LunchItem> library,
  }) {
    final theirs = [
      for (final favourite in favourites)
        if (favourite.childId == child.memberId) favourite,
    ]..sort(LunchFavourite.inRotationOrder);
    return LunchChildWeek(
      child: child,
      plan: plan,
      taste: LunchTaste.from(history: history, current: week),
      favourites: theirs,
      unsafeFavouriteIds: {
        for (final favourite in theirs)
          if (favourite.box.filled.any(
            (entry) => !LunchSafety.isSafe(
              allergens: {
                ...entry.$2.knownAllergens,
                ...?library[entry.$2.itemId]?.knownAllergens,
              },
              rules: child.foodRules,
            ),
          ))
            favourite.id,
      },
      days: [
        for (final date in week.schoolDays)
          LunchDay.of(
            date: date,
            today: today,
            box: plan.boxOn(date.weekday),
            feedback: plan.feedbackOn(date.weekday),
            rules: child.foodRules,
            library: library,
          ),
      ],
    );
  }

  final FamilyEntry child;
  final LunchPlan plan;
  final LunchTaste taste;

  /// Theirs only, in rotation order.
  final List<LunchFavourite> favourites;

  /// Go-to boxes that hold something no longer safe for them — flagged, and
  /// skipped by auto-fill.
  final Set<String> unsafeFavouriteIds;
  final List<LunchDay> days;

  String get childId => child.memberId;

  bool get isEmpty => plan.isEmpty;

  int get unsafeCount => days.where((day) => day.hasUnsafe).length;

  LunchDay? dayOn(int isoWeekday) =>
      days.where((day) => day.date.weekday == isoWeekday).firstOrNull;

  int get filledDays => days.where((day) => !day.box.isEmpty).length;

  /// A slot's library ranked for this child, counting what their week
  /// already holds (lunch-box ADR-0003) — what the picker shows.
  RankedLunchItems rank(LunchSlot slot, Iterable<LunchItem> library) {
    final uses = <String, int>{};
    for (final pick in plan.slots.values) {
      uses[pick.itemId] = (uses[pick.itemId] ?? 0) + 1;
    }
    return LunchSuggestions.rank(
      slot: slot,
      library: library,
      rules: child.foodRules,
      taste: taste,
      usesThisWeek: uses,
    );
  }
}

/// Everything the lunch screen shows for one week: each child's week, and the
/// household's library. Built once per emission of any read (`FE-12`).
@immutable
class LunchBoard {
  LunchBoard({
    required this.week,
    required this.today,
    required List<LunchChildWeek> children,
    required List<LunchItem> library,
  }) : children = List.unmodifiable(children),
       library = List.unmodifiable(library),
       libraryById = Map.unmodifiable({
         for (final item in library) item.id: item,
       });

  /// Every child's week from the reads the controller holds: this week's
  /// plan for each child (or an empty one), and their plans in the window as
  /// the history their suggestions learn from.
  factory LunchBoard.from({
    required LunchWeek week,
    required CalendarDate today,
    required FamilyRoster roster,
    required List<LunchItem> library,
    required List<LunchFavourite> favourites,
    required List<LunchPlan> plans,
  }) {
    final libraryById = {for (final item in library) item.id: item};
    return LunchBoard(
      week: week,
      today: today,
      library: library,
      children: [
        for (final child in roster.children)
          LunchChildWeek.of(
            child: child,
            week: week,
            today: today,
            plan:
                plans
                    .where(
                      (plan) =>
                          plan.id == LunchPlan.idFor(child.memberId, week),
                    )
                    .firstOrNull ??
                LunchPlan.empty(childId: child.memberId, week: week),
            history: [
              for (final plan in plans)
                if (plan.childId == child.memberId) plan,
            ],
            favourites: favourites,
            library: libraryById,
          ),
      ],
    );
  }

  final LunchWeek week;
  final CalendarDate today;
  final List<LunchChildWeek> children;

  /// Every item, put away or not — a put-away item still names past boxes.
  final List<LunchItem> library;
  final Map<String, LunchItem> libraryById;

  bool get hasChildren => children.isNotEmpty;

  LunchChildWeek? childWeek(String childId) =>
      children.where((entry) => entry.childId == childId).firstOrNull;

  /// Whether this is the week being planned now — see
  /// `LunchWeek.planningFor`.
  bool get isThisWeek => week == LunchWeek.planningFor(today);

  /// The box that matters next in a child's week: today's on a school day,
  /// Monday's for a week still to come, Friday's for one that has gone.
  LunchDay focusDayOf(LunchChildWeek childWeek) {
    final days = childWeek.days;
    return days.where((day) => day.isToday).firstOrNull ??
        days.where((day) => day.date.isAfter(today)).firstOrNull ??
        days.last;
  }
}
