import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/state/action_failure.dart';
import '../../../shared/time/calendar_date.dart';
import '../data/kid_routine_repository.dart';
import '../model/kid_routine.dart';
import '../model/kid_routine_run.dart';
import '../model/kid_routine_step.dart';
import '../model/kid_routine_tick.dart';

/// A child's routines for today, on their own home (kid-routines ADR-0001):
/// the routines naming them and today's ticks, joined into runs, and the one
/// thing a child does to a run — tick a step, or untick it.
///
/// It opens only once the home says what today is and that the grant shows
/// jobs, and closes again when either stops being so, so the device never
/// asks for what it may not see (accounts ADR-0004).
final class KidRoutineDayController extends ChangeNotifier
    with ActionFailureHolder {
  KidRoutineDayController({
    required this._repository,
    required this.householdId,
    required this.kidId,
  });

  final KidRoutineRepository _repository;
  final String householdId;
  final String kidId;

  final _subscriptions = <StreamSubscription<Object?>>[];
  CalendarDate? _today;
  bool _canTick = false;
  bool _disposed = false;
  List<KidRoutine>? _routines;
  List<KidRoutineTick>? _ticks;
  AsyncState<List<KidRoutineRun>>? _runs;

  /// Null while routines are not shown at all.
  AsyncState<List<KidRoutineRun>>? get runs => _runs;

  /// `view` on to-dos looks and does not tick.
  bool get canTick => _canTick;

  KidRoutineRun? runFor(String routineId) {
    final runs = _runs;
    if (runs is! AsyncData<List<KidRoutineRun>>) return null;
    for (final run in runs.value) {
      if (run.routine.id == routineId) return run;
    }
    return null;
  }

  void follow({
    required bool show,
    required bool canTick,
    required CalendarDate? today,
  }) {
    final next = show ? today : null;
    final changed = next != _today;
    final tickChanged = canTick != _canTick;
    _today = next;
    _canTick = canTick;
    if (changed) {
      unawaited(_reopen());
    } else if (tickChanged) {
      scheduleMicrotask(_notify);
    }
  }

  Future<void> retry() => _reopen();

  Future<void> toggle(KidRoutineRun run, KidRoutineStep step) => runAction(
    () => _repository.saveTick(
      householdId: householdId,
      tick: KidRoutineTick(
        routineId: run.routine.id,
        kidId: kidId,
        occurrenceDate: run.date,
        doneStepIds: run.doneAfterToggling(step),
        updatedBy: kidId,
      ),
    ),
  );

  Future<void> _reopen() async {
    await _cancel();
    _routines = null;
    _ticks = null;
    final today = _today;
    _runs = today == null ? null : const AsyncLoading();
    _notify();
    if (today == null || _disposed) return;
    _listen(
      _repository.watchRoutinesFor(householdId: householdId, kidId: kidId),
      (routines) => _routines = routines,
    );
    _listen(
      _repository.watchTicks(
        householdId: householdId,
        kidId: kidId,
        date: today,
      ),
      (ticks) => _ticks = ticks,
    );
  }

  void _listen<T>(Stream<T> stream, void Function(T value) keep) {
    _subscriptions.add(
      stream.listen(
        (value) {
          keep(value);
          _publish();
        },
        onError: (Object error) {
          _runs = AsyncFailure(
            error is AppFailure ? error : UnknownFailure(error),
          );
          _notify();
        },
      ),
    );
  }

  void _publish() {
    final (routines, ticks, today) = (_routines, _ticks, _today);
    if (routines == null || ticks == null || today == null) return;
    _runs = AsyncData(
      KidRoutineRun.forDay(
        routines: routines,
        ticks: ticks,
        kidId: kidId,
        date: today,
      ),
    );
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _cancel() async {
    final subscriptions = [..._subscriptions];
    _subscriptions.clear();
    for (final subscription in subscriptions) {
      await subscription.cancel();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_cancel());
    super.dispose();
  }
}
