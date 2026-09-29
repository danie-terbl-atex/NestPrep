import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/state/action_failure.dart';
import '../data/cleaning_job_repository.dart';
import '../data/job_photo_store.dart';
import '../model/cleaning_job.dart';
import '../model/home_care_board.dart';
import '../model/job_event.dart';
import 'job_actions.dart';

/// One job, for its detail, its step-through and its review — three screens
/// sharing one controller on one route (home-care ADR-0001).
///
/// The job itself is the shell's board, followed rather than copied
/// (`FE-07`); what is this controller's own is the job's history and the
/// bytes of its photos, which only this job's screens need.
final class JobController extends ChangeNotifier with ActionFailureHolder {
  JobController({
    required CleaningJobRepository jobRepository,
    required this._photoStore,
    required this.householdId,
    required this.jobId,
    required JobActions Function(JobController controller) actions,
  }) : _jobs = jobRepository {
    this.actions = actions(this);
    _listenToHistory();
  }

  final CleaningJobRepository _jobs;
  final JobPhotoStore _photoStore;
  final String householdId;
  final String jobId;

  /// What can be done to this job — ticking, handing in, reviewing. Kept
  /// apart so this file stays about reading (`ENG-05`).
  late final JobActions actions;

  StreamSubscription<List<JobEvent>>? _history;
  AsyncState<HomeCareBoard> _board = const AsyncLoading();
  AsyncState<List<JobEvent>> _events = const AsyncLoading();
  final _photos = <String, AsyncState<Uint8List>>{};

  AsyncState<List<JobEvent>> get events => _events;

  /// The job as the board has it; null before the board has loaded and
  /// once the job has been deleted. Screens read the board from the shell's
  /// controller; this is for the actions.
  CleaningJob? get currentJob => switch (_board) {
    AsyncData(:final value) => value.jobById(jobId),
    _ => null,
  };

  /// A photo's bytes, loading until they arrive.
  AsyncState<Uint8List> photo(String photoId) =>
      _photos[photoId] ?? const AsyncLoading();

  /// The shell's board moved: a tick, a hand-in, a review. Any photo the job
  /// now names that has not been read yet is read now.
  ///
  /// It says nothing itself: it is called while the shell is building, and
  /// the screens already rebuild from the shell's controller. A photo that
  /// arrives says so when it does.
  void followBoard(AsyncState<HomeCareBoard> board) {
    _board = board;
    final current = currentJob;
    if (current != null) {
      for (final photoId in [
        current.beforePhoto.photoId,
        ?current.afterPhoto?.photoId,
      ]) {
        if (!_photos.containsKey(photoId)) unawaited(_load(photoId));
      }
    }
  }

  /// Reads a photo again after it failed.
  Future<void> retryPhoto(String photoId) => _load(photoId);

  Future<void> _load(String photoId) async {
    _photos[photoId] = const AsyncLoading();
    try {
      final bytes = await _photoStore.read(
        householdId: householdId,
        jobId: jobId,
        photoId: photoId,
      );
      _photos[photoId] = AsyncData(bytes);
    } on AppFailure catch (failure) {
      _photos[photoId] = AsyncFailure(failure);
    }
    if (!_isDisposed) notifyListeners();
  }

  /// Reads the history again after it failed.
  Future<void> retryHistory() async {
    await _cancel();
    _events = const AsyncLoading();
    notifyListeners();
    _listenToHistory();
  }

  void _listenToHistory() {
    _history = _jobs
        .watchEvents(householdId: householdId, jobId: jobId)
        .listen(_onHistory, onError: _onHistoryError);
  }

  void _onHistory(List<JobEvent> events) {
    _events = AsyncData(events);
    notifyListeners();
  }

  void _onHistoryError(Object error) {
    _events = AsyncFailure(error is AppFailure ? error : UnknownFailure(error));
    notifyListeners();
  }

  /// For the actions: keep a refusal for the banner.
  Future<void> run(Future<void> Function() action) => runAction(action);

  /// For the actions: say something moved that is not the board.
  void changed() => notifyListeners();

  var _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    unawaited(_cancel());
    super.dispose();
  }

  Future<void> _cancel() async {
    await _history?.cancel();
    _history = null;
  }
}
