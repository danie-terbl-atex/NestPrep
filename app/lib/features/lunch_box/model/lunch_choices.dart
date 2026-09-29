import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/server_timestamp_converter.dart';
import 'lunch_pick.dart';
import 'lunch_plan.dart';
import 'lunch_slot.dart';
import 'lunch_week.dart';

part 'lunch_choices.freezed.dart';
part 'lunch_choices.g.dart';

/// What a parent lets one child choose from in one week, at
/// `households/{id}/lunchChoices/{childId}_{YYYY-Www}` — the plan's own id
/// (lunch-box ADR-0008).
///
/// [options] holds two or three picks per slot key (`3_main`), each refused
/// by the rules if it is not safe for the child; [chosen] is what the child
/// chose, by item id, so a parent's screen can say so. The plan's slot is the
/// truth of what is in the box.
@freezed
abstract class LunchChoices with _$LunchChoices {
  const factory LunchChoices({
    @JsonKey(includeToJson: false) required String id,
    required String childId,
    required String week,
    @Default(<String, List<LunchPick>>{}) Map<String, List<LunchPick>> options,
    @Default(<String, String>{}) Map<String, String> chosen,

    /// The school day (`'1'`–`'5'`) a parent's last write changed — the
    /// rules check that day's options, and only that day's, so a write stays
    /// inside their thousand-expression budget.
    String? editedDay,

    /// The slot key the child last chose — what the rules read, after the
    /// batch, to know which one slot of the plan a child's write changed.
    String? chosenKey,
    required String updatedBy,
    @ServerTimestampConverter() DateTime? updatedAt,
  }) = _LunchChoices;

  const LunchChoices._();

  factory LunchChoices.fromJson(Map<String, Object?> json) =>
      _$LunchChoicesFromJson(json);

  /// Nothing offered yet — what a week reads before a parent sets anything.
  factory LunchChoices.none({
    required String childId,
    required LunchWeek week,
  }) => LunchChoices(
    id: LunchPlan.idFor(childId, week),
    childId: childId,
    week: week.key,
    updatedBy: '',
  );

  /// A child picks from two or three — fewer is no choice, more is a menu.
  static const fewestOptions = 2;
  static const mostOptions = 3;

  List<LunchPick> optionsAt(int isoWeekday, LunchSlot slot) =>
      options[LunchPlan.slotKey(isoWeekday, slot)] ?? const [];

  String? chosenAt(int isoWeekday, LunchSlot slot) =>
      chosen[LunchPlan.slotKey(isoWeekday, slot)];

  bool hasOptionsOn(int isoWeekday) =>
      LunchSlot.values.any((slot) => optionsAt(isoWeekday, slot).isNotEmpty);

  bool get isEmpty => options.isEmpty;
}
