import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/state/action_failure.dart';
import '../../household/model/member.dart';
import '../data/kid_routine_repository.dart';
import '../model/kid_routine.dart';
import '../model/kid_routine_board.dart';
import '../model/kid_routine_draft.dart';

/// The parent's routines screen (kid-routines ADR-0001): one live read of the
/// household's kid routines, joined with its children, and the three things a
/// parent does to one.
final class KidRoutinesController extends ChangeNotifier
    with ActionFailureHolder {
  KidRoutinesController({
    required this._repository,
    required this.householdId,
    required this.memberId,
    required this.canEdit,
    required this.setsStars,
    required this._members,
  }) {
    _subscribe();
  }

  final KidRoutineRepository _repository;
  final String householdId;

  /// The viewer's own profile — who a new routine is made by.
  final String memberId;
  final bool canEdit;

  /// Stars on a routine are family's alone to set.
  final bool setsStars;

  List<Member> _members;
  List<KidRoutine>? _routines;
  StreamSubscription<List<KidRoutine>>? _subscription;
  AsyncState<KidRoutineBoard> _board = const AsyncLoading();

  AsyncState<KidRoutineBoard> get board => _board;

  void followMembers(List<Member> members) {
    _members = members;
    _publish();
  }

  Future<void> retry() async {
    await _subscription?.cancel();
    _routines = null;
    _board = const AsyncLoading();
    notifyListeners();
    _subscribe();
  }

  Future<void> save(KidRoutineDraft draft) => runAction(
    () => _repository.saveRoutine(
      householdId: householdId,
      routine: draft.toRoutine(createdBy: memberId),
    ),
  );

  Future<void> delete(String routineId) => runAction(
    () => _repository.deleteRoutine(
      householdId: householdId,
      routineId: routineId,
    ),
  );

  void _subscribe() {
    _subscription = _repository
        .watchRoutines(householdId)
        .listen(
          (routines) {
            _routines = routines;
            _publish();
          },
          onError: (Object error) {
            _board = AsyncFailure(
              error is AppFailure ? error : UnknownFailure(error),
            );
            notifyListeners();
          },
        );
  }

  void _publish() {
    final routines = _routines;
    if (routines == null) return;
    _board = AsyncData(KidRoutineBoard(routines: routines, members: _members));
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
