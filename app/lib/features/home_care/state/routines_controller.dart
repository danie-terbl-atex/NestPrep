import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/state/action_failure.dart';
import '../../../shared/time/calendar_date.dart';
import '../../household/model/member.dart';
import '../data/routine_repository.dart';
import '../model/home_care_access.dart';
import '../model/home_care_board.dart';
import '../model/home_care_room.dart';
import '../model/routine/room_routine.dart';
import '../model/routine/routine_board.dart';
import '../model/routine/routine_draft.dart';
import '../model/routine/routine_tick.dart';
import '../model/routine/routine_visit.dart';

/// The room routines and this week's ticks — two live reads — with the rooms
/// and members from the home-care shell, as one `RoutineBoard` (home-care
/// ADR-0004, foundation ADR-0006).
///
/// It sits on a shell above the overview, today's rooms and the routine
/// sheet, so moving between them opens no second listener. It follows the
/// home-care controller: a changed grant can move which routines the viewer
/// may ask for (household ADR-0003).
final class RoutinesController extends ChangeNotifier with ActionFailureHolder {
  RoutinesController({
    required RoutineRepository routineRepository,
    required this.householdId,
    required this.today,
    required this._access,
  }) : _routinesRepository = routineRepository {
    _start();
  }

  final RoutineRepository _routinesRepository;
  final String householdId;

  /// Today in the household's zone, fixed for the life of the screen.
  final CalendarDate today;

  HomeCareAccess _access;
  List<HomeCareRoom>? _rooms;
  List<Member> _members = const [];
  AppFailure? _homeFailure;

  StreamSubscription<List<RoomRoutine>>? _routineSubscription;
  StreamSubscription<List<RoutineTick>>? _tickSubscription;
  List<RoomRoutine>? _routines;
  List<RoutineTick>? _ticks;
  AppFailure? _failure;
  AsyncState<RoutineBoard> _board = const AsyncLoading();

  AsyncState<RoutineBoard> get board => _board;

  HomeCareAccess get access => _access;

  CalendarDate get _weekStart => today.weekStart;
  CalendarDate get _weekEnd => _weekStart.addDays(6);

  /// The shell's rooms, members and grant changed.
  void follow(HomeCareAccess access, AsyncState<HomeCareBoard> home) {
    final scopeMoved = access.jobScope != _access.jobScope;
    _access = access;
    switch (home) {
      case AsyncData(value: final value):
        _rooms = value.rooms;
        _members = value.members;
        _homeFailure = null;
      case AsyncFailure(:final failure):
        _homeFailure = failure;
      case AsyncLoading():
        break;
    }
    if (scopeMoved) {
      unawaited(retry());
      return;
    }
    _publish();
  }

  Future<void> retry() async {
    await _cancel();
    _routines = null;
    _ticks = null;
    _failure = null;
    _board = const AsyncLoading();
    notifyListeners();
    _start();
  }

  /// Adds a routine or changes one, stamped with the viewer when new.
  Future<void> save(RoutineDraft draft) => runAction(
    () => _routinesRepository.saveRoutine(
      householdId: householdId,
      routine: draft.toRoutine(createdBy: _access.viewerMemberId ?? ''),
    ),
  );

  Future<void> delete(String routineId) => runAction(
    () => _routinesRepository.deleteRoutine(
      householdId: householdId,
      routineId: routineId,
    ),
  );

  /// Ticks or unticks one item of one day. The listener brings the change
  /// back, from the phone's own cache at once, so nothing is kept here.
  Future<void> toggle(RoutineVisit visit, String itemId) => runAction(
    () => _routinesRepository.setDoneItems(
      householdId: householdId,
      routine: visit.routine,
      day: visit.day,
      doneItemIds: visit.toggled(itemId),
      by: _access.viewerMemberId ?? '',
    ),
  );

  void _start() {
    if (!_access.isVisible) {
      _board = const AsyncFailure(PermissionDeniedFailure());
      return;
    }
    final scope = _access.jobScope;
    _routineSubscription = _routinesRepository
        .watchRoutines(householdId, helperId: scope)
        .listen((routines) {
          _routines = routines;
          _publish();
        }, onError: _onError);
    _tickSubscription = _routinesRepository
        .watchTicks(
          householdId,
          from: _weekStart,
          to: _weekEnd,
          helperId: scope,
        )
        .listen((ticks) {
          _ticks = ticks;
          _publish();
        }, onError: _onError);
  }

  /// Nothing is shown until both reads and the shell's rooms have answered,
  /// so a routine never appears without the room it is for.
  void _publish() {
    final failure = _failure ?? _homeFailure;
    if (failure != null) {
      _board = AsyncFailure(failure);
      notifyListeners();
      return;
    }
    final routines = _routines;
    final ticks = _ticks;
    final rooms = _rooms;
    if (routines == null || ticks == null || rooms == null) return;
    _board = AsyncData(
      RoutineBoard(
        routines: routines,
        ticks: ticks,
        rooms: rooms,
        members: _members,
        today: today,
      ),
    );
    notifyListeners();
  }

  void _onError(Object error) {
    _failure = error is AppFailure ? error : UnknownFailure(error);
    _publish();
  }

  Future<void> _cancel() async {
    await _routineSubscription?.cancel();
    await _tickSubscription?.cancel();
    _routineSubscription = null;
    _tickSubscription = null;
  }

  @override
  void dispose() {
    unawaited(_cancel());
    super.dispose();
  }
}
