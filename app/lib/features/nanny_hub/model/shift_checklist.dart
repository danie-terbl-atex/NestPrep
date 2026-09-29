import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/server_timestamp_converter.dart';
import 'checklist_item.dart';
import 'shift_moment.dart';

part 'shift_checklist.freezed.dart';
part 'shift_checklist.g.dart';

/// What to do at one part of a shift, at
/// `households/{id}/nannyChecklists/{moment}` — one document per moment, the
/// moment its id (nanny-hub ADR-0001). Ticked per shift, on the shift, so the
/// list itself never changes because somebody did it.
@freezed
abstract class ShiftChecklist with _$ShiftChecklist {
  const factory ShiftChecklist({
    @JsonKey(includeToJson: false) required String id,
    @Default(<ChecklistItem>[]) List<ChecklistItem> items,
    String? updatedBy,
    @ServerTimestampConverter() DateTime? updatedAt,
  }) = _ShiftChecklist;

  const ShiftChecklist._();

  factory ShiftChecklist.fromJson(Map<String, Object?> json) =>
      _$ShiftChecklistFromJson(json);

  factory ShiftChecklist.empty(ShiftMoment moment) =>
      ShiftChecklist(id: moment.name);

  /// Null for a document whose id is not one of the five — written by a
  /// newer build, and left alone rather than shown under the wrong heading.
  ShiftMoment? get moment => ShiftMoment.fromName(id);

  /// What a shift's `ticks` map calls one of these items.
  static String tickKey(ShiftMoment moment, String itemId) =>
      '${moment.name}:$itemId';
}
