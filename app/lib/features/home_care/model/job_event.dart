import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/server_timestamp_converter.dart';
import 'job_status.dart';

part 'job_event.freezed.dart';
part 'job_event.g.dart';

/// One line of a job's history, at
/// `households/{id}/homeCareJobs/{jobId}/events/{revision}`: the status the
/// job moved to, who moved it, and the note when it was sent back. Written in
/// the same batch as the change and never rewritten (home-care ADR-0001).
@freezed
abstract class JobEvent with _$JobEvent {
  const factory JobEvent({
    /// The revision the job moved to, as its document id.
    @JsonKey(includeToJson: false) required String id,
    @JsonKey(unknownEnumValue: JobStatus.assigned) required JobStatus status,

    /// The member profile that made the change.
    required String by,
    String? note,
    @ServerTimestampConverter() DateTime? at,
  }) = _JobEvent;

  const JobEvent._();

  factory JobEvent.fromJson(Map<String, Object?> json) =>
      _$JobEventFromJson(json);

  /// The revision, for ordering; an id that is not a number sorts first.
  int get revision => int.tryParse(id) ?? -1;
}
