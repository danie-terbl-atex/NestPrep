import 'package:flutter/foundation.dart';

import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/best_effort.dart';
import '../../../shared/state/action_failure.dart';
import '../../../shared/time/calendar_date.dart';
import '../data/cleaning_job_repository.dart';
import '../data/job_photo_store.dart';
import '../data/photo_source.dart';
import '../model/compressed_photo.dart';
import '../model/job_details.dart';
import '../model/job_photo.dart';
import '../model/spot_mark.dart';
import 'photo_intake.dart';

/// A new job while a parent puts it together: the photo, the circles drawn
/// over it, and the details. Nothing is stored until it is assigned — then
/// the photo goes up first and the job that names it second
/// (home-care ADR-0003).
final class JobComposerController extends ChangeNotifier
    with ActionFailureHolder {
  JobComposerController({
    required CleaningJobRepository jobRepository,
    required JobPhotoStore photoStore,
    required PhotoIntake photoIntake,
    required this.householdId,
    required this.memberId,
    required this.viewerUid,
    required CalendarDate today,
  }) : _jobs = jobRepository,
       _photos = photoStore,
       _intake = photoIntake,
       _details = JobDetails(dueDate: today);

  final CleaningJobRepository _jobs;
  final JobPhotoStore _photos;
  final PhotoIntake _intake;
  final String householdId;

  /// The profile the job is made in the name of, and the account whose uid
  /// the photo is stamped with.
  final String memberId;
  final String viewerUid;

  CompressedPhoto? _photo;
  List<SpotMark> _marks = const [];
  JobDetails _details;
  bool _isTakingPhoto = false;
  bool _isSaving = false;
  bool _hasTriedToSave = false;

  CompressedPhoto? get photo => _photo;
  List<SpotMark> get marks => _marks;
  JobDetails get details => _details;
  bool get isTakingPhoto => _isTakingPhoto;
  bool get isSaving => _isSaving;

  /// Problems are shown once somebody has tried to assign, not while they are
  /// still filling the form in (`FE-10`).
  List<JobDetailsProblem> get shownProblems =>
      _hasTriedToSave ? _details.problems : const [];

  /// Said beside the photo once somebody tried to assign without one.
  bool get isMissingPhoto => _hasTriedToSave && _photo == null;

  bool get isReady => _photo != null && _details.isComplete;

  Future<void> takePhoto(PhotoOrigin origin) async {
    if (_isTakingPhoto || _isSaving) return;
    _isTakingPhoto = true;
    notifyListeners();
    await runAction(() async {
      final taken = await _intake.take(origin);
      if (taken == null) return;
      _photo = taken;
      // Circles drawn round a spot on another photo mean nothing on this one.
      _marks = const [];
    });
    _isTakingPhoto = false;
    notifyListeners();
  }

  void setMarks(List<SpotMark> marks) {
    _marks = marks.take(SpotMark.limit).toList();
    notifyListeners();
  }

  /// Applies a change to the details as they stand now.
  void updateDetails(JobDetails Function(JobDetails details) change) {
    _details = change(_details);
    notifyListeners();
  }

  /// Stores the photo, then the job. True once the job exists.
  Future<bool> assign() async {
    if (_isSaving) return false;
    _hasTriedToSave = true;
    final photo = _photo;
    if (photo == null || !_details.isComplete) {
      notifyListeners();
      return false;
    }
    _isSaving = true;
    clearFailureQuietly();
    notifyListeners();
    final jobId = _jobs.newJobId(householdId);
    var isDone = false;
    try {
      await _photos.upload(
        householdId: householdId,
        jobId: jobId,
        photoId: JobPhoto.beforeId,
        uploaderUid: viewerUid,
        photo: photo,
      );
      await _createOrTidyUp(jobId, photo);
      isDone = true;
    } on AppFailure catch (failure) {
      recordFailure(failure);
    } finally {
      _isSaving = false;
      notifyListeners();
    }
    return isDone;
  }

  /// The job, or — when it is refused — the photo it would have named, so a
  /// failed assign does not leave bytes nobody can list.
  Future<void> _createOrTidyUp(String jobId, CompressedPhoto photo) async {
    try {
      await _jobs.createJob(
        householdId: householdId,
        jobId: jobId,
        details: _details,
        beforePhoto: photo.named(JobPhoto.beforeId),
        marks: _marks,
        createdBy: memberId,
      );
    } on AppFailure {
      await bestEffort(
        'remove orphaned job photo',
        code: 'orphan-photo',
        run: () => _photos.remove(
          householdId: householdId,
          jobId: jobId,
          photoId: JobPhoto.beforeId,
        ),
      );
      rethrow;
    }
  }
}
