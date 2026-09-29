import '../../../shared/log/best_effort.dart';
import '../../../shared/time/calendar_date.dart';
import '../data/activity_recorder.dart';

/// Says "this household was opened today" at most once a day per household
/// (product-analytics ADR-0001).
///
/// Once a day is enough: the server counts *who* was active in a *week*, and
/// adds a member to a set, so a second call changes nothing and only costs an
/// invocation. A call that fails is not marked done, so the next time the app
/// comes to the front it is tried again.
///
/// It is best-effort on purpose (`best_effort.dart`). Nobody is waiting on it
/// and nothing on screen depends on it; a household's week must open whether
/// or not the count reached the server. The failure is logged, never shown.
final class ActivityHeartbeat {
  ActivityHeartbeat({
    required ActivityRecorder activityRecorder,
    DateTime Function()? now,
  }) : _recorder = activityRecorder,
       _now = now ?? DateTime.now;

  final ActivityRecorder _recorder;
  final DateTime Function() _now;

  /// The day each household was last counted on, on this device.
  final Map<String, CalendarDate> _countedOn = {};

  /// Calls already on their way, so two quick resumes send one call.
  final Map<String, Future<void>> _inFlight = {};

  /// Counts [householdId] as opened today, unless it already has been.
  Future<void> beat(String householdId) {
    final today = CalendarDate.fromDateTime(_now());
    if (_countedOn[householdId] == today) return Future.value();
    final pending = _inFlight[householdId];
    if (pending != null) return pending;
    // Removed by a void callback, not an arrow: an arrow would hand
    // `whenComplete` the removed future — this one — to wait for, and it would
    // wait for itself for ever.
    final call = _send(householdId, today).whenComplete(() {
      _inFlight.remove(householdId);
    });
    _inFlight[householdId] = call;
    return call;
  }

  Future<void> _send(String householdId, CalendarDate today) async {
    final failure = await bestEffort(
      'record activity',
      code: 'functions',
      run: () => _recorder.recordActivity(householdId),
    );
    if (failure == null) _countedOn[householdId] = today;
  }
}
