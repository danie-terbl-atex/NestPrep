import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../data/cleaning_job_repository.dart';
import '../data/job_photo_store.dart';
import '../data/photo_source.dart';
import '../model/cleaning_job.dart';
import '../model/compressed_photo.dart';
import '../model/job_details.dart';
import '../model/job_photo.dart';
import '../model/job_status.dart';
import 'job_controller.dart';
import 'photo_intake.dart';

/// What can be done to one job: the helper's ticks and hand-in, and the
/// parent's review, edit and delete (home-care ADR-0001). Every write goes
/// through the job controller's runner, so a refusal reaches the banner.
final class JobActions {
  JobActions({
    required this._controller,
    required CleaningJobRepository jobRepository,
    required JobPhotoStore photoStore,
    required PhotoIntake photoIntake,
    required this.memberId,
    required this.viewerUid,
  }) : _jobs = jobRepository,
       _photos = photoStore,
       _intake = photoIntake;

  final JobController _controller;
  final CleaningJobRepository _jobs;
  final JobPhotoStore _photos;
  final PhotoIntake _intake;

  /// Who the viewer is: the profile writes are made in the name of, and the
  /// account an uploaded photo is stamped with.
  final String memberId;
  final String viewerUid;

  String get _householdId => _controller.householdId;

  CompressedPhoto? _afterPhoto;
  bool _isTakingPhoto = false;
  bool _isBusy = false;

  /// The after photo taken but not yet handed in.
  CompressedPhoto? get afterPhoto => _afterPhoto;
  bool get isTakingPhoto => _isTakingPhoto;

  /// A hand-in, a review or a delete is on its way.
  bool get isBusy => _isBusy;

  /// Ticks a step, or unticks it. The first tick starts the job.
  Future<void> toggleStep(String stepId) async {
    final job = _controller.currentJob;
    if (job == null || !job.status.isWithHelper) return;
    final done = job.isStepDone(stepId)
        ? [
            for (final id in job.doneStepIds)
              if (id != stepId) id,
          ]
        : [...job.doneStepIds, stepId];
    await _controller.run(
      () => _jobs.setDoneSteps(
        householdId: _householdId,
        job: job,
        doneStepIds: done,
        by: memberId,
      ),
    );
  }

  Future<void> takeAfterPhoto(PhotoOrigin origin) async {
    if (_isTakingPhoto) return;
    _isTakingPhoto = true;
    _controller.changed();
    await _controller.run(() async {
      final taken = await _intake.take(origin);
      if (taken != null) _afterPhoto = taken;
    });
    _isTakingPhoto = false;
    _controller.changed();
  }

  /// Stores the after photo under this hand-in's name, then hands the job in.
  /// True once it has been.
  Future<bool> handIn() {
    final job = _controller.currentJob;
    final photo = _afterPhoto;
    if (job == null || photo == null) return Future.value(false);
    return _busy(() async {
      if (!job.areAllStepsDone) {
        throw const HomeCareFailure(HomeCareProblem.stepsNotDone);
      }
      final photoId = job.nextAfterPhotoId;
      await _photos.upload(
        householdId: _householdId,
        jobId: job.id,
        photoId: photoId,
        uploaderUid: viewerUid,
        photo: photo,
      );
      await _jobs.handIn(
        householdId: _householdId,
        job: job,
        afterPhoto: photo.named(photoId),
        by: memberId,
      );
      _afterPhoto = null;
    });
  }

  Future<bool> approve() => _reviewing(
    (job) => _jobs.approve(householdId: _householdId, job: job, by: memberId),
  );

  Future<bool> sendBack(String note) => _reviewing(
    (job) => _jobs.sendBack(
      householdId: _householdId,
      job: job,
      note: note.trim(),
      by: memberId,
    ),
  );

  Future<bool> updateDetails(JobDetails details) {
    final job = _controller.currentJob;
    if (job == null || !details.isComplete) return Future.value(false);
    return _busy(
      () => _jobs.updateDetails(
        householdId: _householdId,
        job: job,
        details: details,
      ),
    );
  }

  /// Removes the job's photos, then the job and its history. A photo that is
  /// already gone is not a reason to stop.
  Future<bool> delete() {
    final job = _controller.currentJob;
    if (job == null) return Future.value(false);
    return _busy(() async {
      for (final photoId in _photoIdsOf(job)) {
        try {
          await _photos.remove(
            householdId: _householdId,
            jobId: job.id,
            photoId: photoId,
          );
        } on NotFoundFailure {
          continue;
        }
      }
      await _jobs.deleteJob(householdId: _householdId, jobId: job.id);
    });
  }

  /// Every photo the job has had: the before photo and one after photo per
  /// hand-in, each named for the revision it was handed in at.
  Iterable<String> _photoIdsOf(CleaningJob job) sync* {
    yield JobPhoto.beforeId;
    final events = _controller.events;
    final handIns = switch (events) {
      AsyncData(:final value) => [
        for (final event in value)
          if (event.status == JobStatus.submitted) event.revision,
      ],
      _ => <int>[],
    };
    final after = job.afterPhoto?.photoId;
    final named = {
      for (final revision in handIns) JobPhoto.afterIdFor(revision),
    };
    yield* {...named, ?after};
  }

  Future<bool> _reviewing(Future<void> Function(CleaningJob job) review) {
    final job = _controller.currentJob;
    if (job == null || !job.status.isWaitingForReview) {
      return Future.value(false);
    }
    return _busy(() => review(job));
  }

  Future<bool> _busy(Future<void> Function() action) async {
    if (_isBusy) return false;
    _isBusy = true;
    _controller.changed();
    var isDone = false;
    await _controller.run(() async {
      await action();
      isDone = true;
    });
    _isBusy = false;
    _controller.changed();
    return isDone;
  }
}
