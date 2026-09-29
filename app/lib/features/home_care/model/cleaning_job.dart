import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/server_timestamp_converter.dart';
import '../../../shared/recurrence/calendar_date_converter.dart';
import '../../../shared/time/calendar_date.dart';
import 'job_photo.dart';
import 'job_status.dart';
import 'job_step.dart';
import 'spot_mark.dart';

part 'cleaning_job.freezed.dart';
part 'cleaning_job.g.dart';

/// A cleaning job, at `households/{id}/homeCareJobs/{jobId}` (home-care
/// ADR-0001): a photo of a spot with the spot circled, a room, one helper, a
/// due day, the products to use, the steps to follow, and — once handed in —
/// the after photo.
///
/// Its status moves only along the edges the rules allow, and every move bumps
/// [revision] and writes one history event named for it in the same batch.
@freezed
abstract class CleaningJob with _$CleaningJob {
  const factory CleaningJob({
    @JsonKey(includeToJson: false) required String id,
    required String title,
    required String roomId,

    /// The member profile doing it — claimed or not. What `own` means.
    required String helperId,

    /// A day in the household's zone, never an instant (`ENG-21`).
    @CalendarDateConverter() required CalendarDate dueDate,
    String? note,
    @Default(<String>[]) List<String> productIds,
    @Default(<JobStep>[]) List<JobStep> steps,
    @Default(<String>[]) List<String> doneStepIds,
    required JobPhoto beforePhoto,
    @Default(<SpotMark>[]) List<SpotMark> marks,
    JobPhoto? afterPhoto,
    @JsonKey(unknownEnumValue: JobStatus.assigned)
    @Default(JobStatus.assigned)
    JobStatus status,

    /// The latest send-back note, which the helper reads until she hands the
    /// job in again. The history keeps every one.
    String? reviewNote,
    @Default(0) int revision,
    required String createdBy,
    @ServerTimestampConverter() DateTime? createdAt,
    @ServerTimestampConverter() DateTime? updatedAt,
  }) = _CleaningJob;

  const CleaningJob._();

  factory CleaningJob.fromJson(Map<String, Object?> json) =>
      _$CleaningJobFromJson(json);

  /// What the rules keep: a title's length, a note's, and how many steps and
  /// products one job carries.
  static const titleLimit = 80;
  static const noteLimit = 500;
  static const stepLimit = 30;
  static const productLimit = 20;

  bool isStepDone(String stepId) => doneStepIds.contains(stepId);

  /// Only the ticks for steps the job still has — a step a parent removed
  /// does not count towards handing in.
  int get doneCount => steps.where((step) => isStepDone(step.id)).length;

  bool get areAllStepsDone => doneCount == steps.length;

  /// How far through, from 0 to 1, for the progress bar.
  double get progress => steps.isEmpty ? 1 : doneCount / steps.length;

  /// The name the next hand-in's photo is stored under.
  String get nextAfterPhotoId => JobPhoto.afterIdFor(revision + 1);

  /// Due before [today] and still not handed in.
  bool isOverdue(CalendarDate today) =>
      status.isWithHelper && dueDate.compareTo(today) < 0;
}
