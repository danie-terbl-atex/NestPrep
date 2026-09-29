import 'package:flutter/foundation.dart';

import '../../../shared/failure/app_failure.dart';
import '../../lunch_box/data/lunch_repository.dart';
import '../../lunch_box/model/lunch_board.dart';
import '../../lunch_box/model/lunch_item.dart';
import '../../lunch_box/model/lunch_item_draft.dart';
import '../../lunch_box/model/lunch_pick.dart';
import '../../lunch_box/model/lunch_safety.dart';
import '../../meal_planning/data/meal_repository.dart';
import '../../meal_planning/model/week_plan.dart';
import '../model/planned_week.dart';

/// What using a plan wrote.
@immutable
final class PlanWeekSaved {
  const PlanWeekSaved({
    required this.lunches,
    required this.dinners,
    required this.skipped,
  });

  /// Compartments packed, across every child.
  final int lunches;

  /// Dinners put on the meal plan, new ideas included.
  final int dinners;

  /// Proposed things not written: filled by somebody else meanwhile, no longer
  /// safe for the child, or refused by the rules.
  final int skipped;
}

/// Writes a plan a parent chose to use (lunch-box ADR-0011) — through the
/// same repositories and under the same rules as packing a box or filling a
/// dinner by hand, so the allergy refusal still applies to every compartment
/// (lunch-box ADR-0001) and a lunch plan write still carries one school day
/// (ADR-0010, inside `setPicks`).
///
/// Nothing somebody filled since the plan was made is replaced: each child's
/// week and the dinners are read again as the phone holds them now.
final class PlanWeekSaver {
  PlanWeekSaver({
    required LunchRepository lunchRepository,
    required MealRepository mealRepository,
    required this.householdId,
    required this.memberId,
  }) : _lunches = lunchRepository,
       _meals = mealRepository;

  final LunchRepository _lunches;
  final MealRepository _meals;
  final String householdId;
  final String memberId;

  /// Adds something new to the library from the review's picker, and gives
  /// it back with its id — or the household's own item by that name.
  Future<LunchItem> addToLibrary(LunchItemDraft draft) async {
    final item = draft.toNewItem(memberId);
    final id = await _lunches.addItem(householdId, item);
    return item.copyWith(id: id);
  }

  Future<PlanWeekSaved> save(
    PlannedWeek plan, {
    required LunchBoard board,
    required WeekPlan? mealPlan,
  }) async {
    var lunches = 0;
    var skipped = 0;
    for (final planned in plan.children) {
      final now = board.childWeek(planned.childId);
      if (now == null) {
        skipped += planned.added.length;
        continue;
      }
      final picks = <String, LunchPick>{};
      for (final MapEntry(:key, :value) in planned.added.entries) {
        final item = board.libraryById[value.item.id] ?? value.item;
        final isSafe = LunchSafety.isSafe(
          allergens: item.knownAllergens,
          rules: now.child.foodRules,
        );
        if (now.plan.slots.containsKey(key) || !isSafe) {
          skipped++;
        } else {
          picks[key] = LunchPick.of(item);
        }
      }
      if (picks.isEmpty) continue;
      try {
        await _lunches.setPicks(
          householdId: householdId,
          childId: planned.childId,
          week: plan.week,
          picks: picks,
        );
        lunches += picks.length;
      } on PermissionDeniedFailure {
        // The rules said no — the child's rules changed on another phone.
        // The other children's weeks still go in.
        skipped += picks.length;
      }
    }

    final slots = <String, String>{};
    for (final MapEntry(key: day, value: dinner) in plan.dinners.entries) {
      if ((mealPlan?.mealIdAt(day, MealSlot.dinner) ?? '').isNotEmpty) {
        skipped++;
        continue;
      }
      slots[WeekPlan.slotKey(day, MealSlot.dinner)] = switch (dinner) {
        LibraryDinner(:final meal) => meal.id,
        IdeaDinner(:final idea) => await _meals.addMeal(
          householdId: householdId,
          name: idea.name,
          addedBy: memberId,
        ),
      };
    }
    if (slots.isNotEmpty) {
      await _meals.setSlots(
        householdId: householdId,
        monday: plan.week.monday,
        slots: slots,
      );
    }
    return PlanWeekSaved(
      lunches: lunches,
      dinners: slots.length,
      skipped: skipped,
    );
  }
}
