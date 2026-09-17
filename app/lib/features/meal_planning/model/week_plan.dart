import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/time/calendar_date.dart';

part 'week_plan.freezed.dart';
part 'week_plan.g.dart';

/// The three meals a day has (meal-planning ADR-0001). No snacks: nobody asked.
enum MealSlot { breakfast, lunch, dinner }

/// One week's plan, at `households/{id}/mealPlans/{mondayDate}`
/// (meal-planning ADR-0001).
///
/// One document for the whole week means one listener, one write per slot
/// change, and the week reads offline from a single cached document. Slots are
/// a flat map keyed `{isoWeekday}_{slot}` — flat so a single slot is one field
/// update, and keyed by weekday rather than by date so copying last week is the
/// same keys.
@freezed
abstract class WeekPlan with _$WeekPlan {
  const factory WeekPlan({
    /// The Monday this week starts on, `YYYY-MM-DD` — also the document id.
    @JsonKey(includeToJson: false) required String id,
    @Default(<String, String>{}) Map<String, String> slots,
  }) = _WeekPlan;

  const WeekPlan._();

  factory WeekPlan.fromJson(Map<String, Object?> json) =>
      _$WeekPlanFromJson(json);

  /// An empty week, for one that has never been planned.
  factory WeekPlan.empty(CalendarDate monday) => WeekPlan(id: monday.iso);

  /// Seven days, three meals each — the whole shape of a week (ADR-0001).
  static const daysInAWeek = 7;
  static const slotCount = daysInAWeek * 3;

  static String slotKey(int isoWeekday, MealSlot slot) =>
      '${isoWeekday}_${slot.name}';

  /// The meal filled into one slot, or null when nothing is planned.
  String? mealIdAt(int isoWeekday, MealSlot slot) =>
      slots[slotKey(isoWeekday, slot)];

  bool get isEmpty => slots.values.every((mealId) => mealId.isEmpty);

  /// Every slot this week has something in, as the keys a copy would write.
  Map<String, String> get filledSlots => {
    for (final entry in slots.entries)
      if (entry.value.isNotEmpty) entry.key: entry.value,
  };

  /// What copying [previous] into this week would write (meal-planning
  /// ADR-0001): only the empty slots, unless [overwrite] is asked for.
  Map<String, String> slotsCopiedFrom(
    WeekPlan previous, {
    bool overwrite = false,
  }) => {
    for (final entry in previous.filledSlots.entries)
      if (overwrite || (slots[entry.key] ?? '').isEmpty) entry.key: entry.value,
  };

  /// The keys that named a meal which no longer exists — clearing them is what
  /// deleting a meal means for a plan (meal-planning ADR-0001).
  List<String> slotsUsing(String mealId) => [
    for (final entry in slots.entries)
      if (entry.value == mealId) entry.key,
  ];
}
