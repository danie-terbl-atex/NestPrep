import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/server_timestamp_converter.dart';
import '../../../shared/recurrence/calendar_date_converter.dart';
import '../../../shared/recurrence/recurrence_rule.dart';
import '../../../shared/time/calendar_date.dart';

part 'task.freezed.dart';
part 'task.g.dart';

/// A todo at `households/{id}/tasks/{taskId}` (todos ADR-0001).
///
/// A due date is a calendar date, not an instant: "bins out on Tuesday" is the
/// household's Tuesday wherever anybody happens to be (`ENG-21`). A task with no
/// recurrence is the degenerate case of one occurrence on its due date
/// (foundation ADR-0005).
@freezed
abstract class Task with _$Task {
  const factory Task({
    @JsonKey(includeToJson: false) required String id,
    required String title,
    String? note,
    @CalendarDateConverter() required CalendarDate dueDate,
    RecurrenceRule? recurrence,

    /// The member profiles this is for. **Empty means anyone**, which is what
    /// "somebody take the bins out" actually means.
    @Default(<String>[]) List<String> assigneeIds,

    /// The member profile that created it — not the account.
    required String createdBy,

    /// The routine this belongs to, whose schedule it then follows.
    String? routineId,
    @ServerTimestampConverter() DateTime? createdAt,

    /// The stars a child earns for doing it — 0 for none (todos ADR-0003).
    /// Only family sets it, and a starred chore always names its children.
    @Default(0) int points,

    /// Whether a parent checks it before the stars land (todos ADR-0003).
    @Default(false) bool needsApproval,
  }) = _Task;

  const Task._();

  factory Task.fromJson(Map<String, Object?> json) => _$TaskFromJson(json);

  /// Whether ticking it earns a child anything.
  bool get carriesStars => points > 0;
}
