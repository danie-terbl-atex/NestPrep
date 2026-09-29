import 'package:freezed_annotation/freezed_annotation.dart';

import 'lunch_box.dart';
import 'lunch_feedback.dart';
import 'lunch_pick.dart';
import 'lunch_slot.dart';
import 'lunch_week.dart';

part 'lunch_plan.freezed.dart';
part 'lunch_plan.g.dart';

/// One child's lunches for one school week, at
/// `households/{id}/lunchPlans/{childId}_{YYYY-Www}` (lunch-box ADR-0001).
///
/// Keyed by child and week so a re-made plan is the same document — which is
/// also what product-analytics counts as one plan made. Slots are a flat map
/// keyed `{isoWeekday}_{slot}` like the meal plan's, so one swap is one field
/// and the rules can check the slots a write changed, by name.
@freezed
abstract class LunchPlan with _$LunchPlan {
  const factory LunchPlan({
    @JsonKey(includeToJson: false) required String id,
    required String childId,

    /// `YYYY-Www` — also the tail of the document id.
    required String week,

    /// The Monday, `YYYY-MM-DD`, which the household's listener orders and
    /// bounds by.
    required String weekStart,
    @Default(<String, LunchPick>{}) Map<String, LunchPick> slots,

    /// Weekday (`'1'`–`'5'`) → what came home that day.
    @Default(<String, LunchFeedback>{}) Map<String, LunchFeedback> feedback,
  }) = _LunchPlan;

  const LunchPlan._();

  factory LunchPlan.fromJson(Map<String, Object?> json) =>
      _$LunchPlanFromJson(json);

  /// The plan for a week nobody has planned yet.
  factory LunchPlan.empty({required String childId, required LunchWeek week}) =>
      LunchPlan(
        id: idFor(childId, week),
        childId: childId,
        week: week.key,
        weekStart: week.monday.iso,
      );

  static String idFor(String childId, LunchWeek week) =>
      '${childId}_${week.key}';

  static String slotKey(int isoWeekday, LunchSlot slot) =>
      '${isoWeekday}_${slot.name}';

  /// Every slot key a plan may hold — Monday to Friday, five slots each. The
  /// rules list the same twenty-five by name.
  static final allSlotKeys = [
    for (var day = 1; day <= LunchWeek.schoolDayCount; day++)
      for (final slot in LunchSlot.values) slotKey(day, slot),
  ];

  LunchPick? pickAt(int isoWeekday, LunchSlot slot) =>
      slots[slotKey(isoWeekday, slot)];

  LunchBox boxOn(int isoWeekday) => LunchBox({
    for (final slot in LunchSlot.values) slot: pickAt(isoWeekday, slot),
  });

  LunchFeedback? feedbackOn(int isoWeekday) => feedback['$isoWeekday'];

  bool get isEmpty => slots.isEmpty;

  LunchWeek get lunchWeek => LunchWeek.parse(week);
}
