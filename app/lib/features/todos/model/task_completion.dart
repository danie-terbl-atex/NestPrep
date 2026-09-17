import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/server_timestamp_converter.dart';
import '../../../shared/recurrence/calendar_date_converter.dart';
import '../../../shared/time/calendar_date.dart';

part 'task_completion.freezed.dart';
part 'task_completion.g.dart';

/// One occurrence of one task, done. Stored at
/// `households/{id}/taskCompletions/{taskId}_{date}` — flat under the household
/// rather than under the task, so "what is done this week" is one bounded
/// listener instead of one per task (todos ADR-0002).
///
/// The id is derived from the task and the occurrence's date, so completing the
/// same occurrence twice writes the same document twice and changes nothing.
@freezed
abstract class TaskCompletion with _$TaskCompletion {
  const factory TaskCompletion({
    @JsonKey(includeToJson: false) required String id,
    required String taskId,
    @CalendarDateConverter() required CalendarDate occurrenceDate,

    /// The member who actually did it — the actor.
    required String completedBy,

    /// The member it was for. Different from `completedBy` when an admin
    /// completes on behalf of a profile nobody has claimed (household ADR-0001).
    required String completedFor,
    @ServerTimestampConverter() DateTime? completedAt,
  }) = _TaskCompletion;

  const TaskCompletion._();

  factory TaskCompletion.fromJson(Map<String, Object?> json) =>
      _$TaskCompletionFromJson(json);

  bool get wasOnBehalfOfSomebodyElse => completedBy != completedFor;

  /// The document id for an occurrence. Deriving it rather than generating one
  /// is what makes completing twice harmless (`BE-06`).
  static String idFor(String taskId, CalendarDate date) =>
      '${taskId}_${date.iso}';
}
