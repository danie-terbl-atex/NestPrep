import '../model/cleaning_job.dart';
import '../model/job_details.dart';
import '../model/job_event.dart';
import '../model/job_photo.dart';
import '../model/spot_mark.dart';

/// The household's cleaning jobs and their history (home-care ADR-0001).
///
/// Every status change is one batch: the job at its next revision and the
/// history event named for it. The rules refuse either half on its own.
abstract interface class CleaningJobRepository {
  /// Bounds on the reads (`BE-08`). Jobs are newest-due first, so the limit
  /// drops the oldest finished ones rather than anything still open.
  static const jobLimit = 200;
  static const eventLimit = 100;

  /// Every job, or — for a helper holding `own` — only [helperId]'s, which
  /// is what the rules let her ask for (household ADR-0003).
  Stream<List<CleaningJob>> watchJobs(String householdId, {String? helperId});

  /// One job's history, oldest first.
  Stream<List<JobEvent>> watchEvents({
    required String householdId,
    required String jobId,
  });

  /// An id for a job about to be made, so its photo can be stored under it
  /// before the job exists (home-care ADR-0003).
  String newJobId(String householdId);

  Future<void> createJob({
    required String householdId,
    required String jobId,
    required JobDetails details,
    required JobPhoto beforePhoto,
    required List<SpotMark> marks,
    required String createdBy,
  });

  /// Changes what a job still with its helper says. A tick on a step that
  /// is no longer there is dropped with it.
  Future<void> updateDetails({
    required String householdId,
    required CleaningJob job,
    required JobDetails details,
  });

  /// Ticks and unticks steps. The first tick on a job that is assigned or
  /// was sent back also starts it — a status change, with its event.
  Future<void> setDoneSteps({
    required String householdId,
    required CleaningJob job,
    required List<String> doneStepIds,
    required String by,
  });

  Future<void> handIn({
    required String householdId,
    required CleaningJob job,
    required JobPhoto afterPhoto,
    required String by,
  });

  Future<void> approve({
    required String householdId,
    required CleaningJob job,
    required String by,
  });

  Future<void> sendBack({
    required String householdId,
    required CleaningJob job,
    required String note,
    required String by,
  });

  /// The job and its history. Its photos are the photo store's to remove.
  Future<void> deleteJob({required String householdId, required String jobId});
}
