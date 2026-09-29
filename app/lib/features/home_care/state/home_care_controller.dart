import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/state/action_failure.dart';
import '../../household/model/household_view.dart';
import '../../household/model/member.dart';
import '../data/cleaning_job_repository.dart';
import '../data/home_care_library_repository.dart';
import '../model/cleaning_job.dart';
import '../model/home_care_access.dart';
import '../model/home_care_board.dart';
import '../model/home_care_product.dart';
import '../model/home_care_room.dart';
import 'home_care_library_edits.dart';

/// Home care's shell controller: the jobs, the rooms and the products — three
/// live reads — and the household's members, as one `HomeCareBoard` with one
/// loading state (foundation ADR-0006).
///
/// It lives on the shell above every home-care screen, so walking from the
/// list into a job, its steps and its review opens no second listener. It
/// follows the household view, because a changed grant can move which jobs
/// the viewer may ask for (household ADR-0003).
final class HomeCareController extends ChangeNotifier with ActionFailureHolder {
  HomeCareController({
    required CleaningJobRepository jobRepository,
    required HomeCareLibraryRepository libraryRepository,
    required this.householdId,
    required HouseholdView household,
  }) : _jobs = jobRepository,
       _library = libraryRepository,
       _members = household.members,
       _access = HomeCareAccess.of(household),
       _helpers = HomeCareAccess.helpersIn(household) {
    _start();
  }

  final CleaningJobRepository _jobs;
  final HomeCareLibraryRepository _library;
  final String householdId;

  List<Member> _members;
  HomeCareAccess _access;
  List<Member> _helpers;

  StreamSubscription<List<CleaningJob>>? _jobSubscription;
  StreamSubscription<List<HomeCareRoom>>? _roomSubscription;
  StreamSubscription<List<HomeCareProduct>>? _productSubscription;
  List<CleaningJob>? _jobList;
  List<HomeCareRoom>? _rooms;
  List<HomeCareProduct>? _products;
  AsyncState<HomeCareBoard> _board = const AsyncLoading();

  AsyncState<HomeCareBoard> get board => _board;

  /// What the viewer may do — the rules' mirror (`FE-04`).
  HomeCareAccess get access => _access;

  /// Who a job can be given to.
  List<Member> get helpers => _helpers;

  /// The rooms and products a manager keeps. Kept apart so this file stays
  /// about reading (`ENG-05`).
  late final HomeCareLibraryEdits library = HomeCareLibraryEdits(
    libraryRepository: _library,
    householdId: householdId,
    memberId: () => _access.viewerMemberId ?? '',
    runAction: runAction,
  );

  /// The household's members or the viewer's grant changed.
  void followHousehold(HouseholdView household) {
    final access = HomeCareAccess.of(household);
    if (listEquals(_members, household.members) && access == _access) return;
    final scopeMoved = access.jobScope != _access.jobScope;
    _members = household.members;
    _access = access;
    _helpers = HomeCareAccess.helpersIn(household);
    if (scopeMoved) {
      unawaited(retry());
      return;
    }
    _publish();
  }

  Future<void> retry() async {
    await _cancel();
    _jobList = null;
    _rooms = null;
    _products = null;
    _board = const AsyncLoading();
    notifyListeners();
    _start();
  }

  void _start() {
    if (!_access.isVisible) {
      _board = const AsyncFailure(PermissionDeniedFailure());
      return;
    }
    _jobSubscription = _jobs
        .watchJobs(householdId, helperId: _access.jobScope)
        .listen((jobs) {
          _jobList = jobs;
          _publish();
        }, onError: _onError);
    _roomSubscription = _library.watchRooms(householdId).listen((rooms) {
      _rooms = rooms;
      _publish();
    }, onError: _onError);
    _productSubscription = _library.watchProducts(householdId).listen((
      products,
    ) {
      _products = products;
      _publish();
    }, onError: _onError);
  }

  /// Nothing is shown until all three have answered, so a job never appears
  /// without the room it is in or the products its safety is read from.
  void _publish() {
    final jobs = _jobList;
    final rooms = _rooms;
    final products = _products;
    if (jobs == null || rooms == null || products == null) return;
    _board = AsyncData(
      HomeCareBoard(
        jobs: jobs,
        rooms: rooms,
        products: products,
        members: _members,
      ),
    );
    notifyListeners();
  }

  void _onError(Object error) {
    _board = AsyncFailure(error is AppFailure ? error : UnknownFailure(error));
    notifyListeners();
  }

  Future<void> _cancel() async {
    await _jobSubscription?.cancel();
    await _roomSubscription?.cancel();
    await _productSubscription?.cancel();
    _jobSubscription = null;
    _roomSubscription = null;
    _productSubscription = null;
  }

  @override
  void dispose() {
    unawaited(_cancel());
    super.dispose();
  }
}
