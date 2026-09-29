import 'dart:async';

import '../../../shared/failure/app_failure.dart';
import '../../../shared/time/calendar_date.dart';
import '../../calendar/data/calendar_repository.dart';
import '../../calendar/model/event_exception.dart';
import '../../calendar/model/household_event.dart';
import '../../groceries/data/grocery_repository.dart';
import '../../groceries/model/grocery_item.dart';
import '../../home_care/data/cleaning_job_repository.dart';
import '../../home_care/model/cleaning_job.dart';
import '../../lunch_box/data/lunch_repository.dart';
import '../../lunch_box/model/lunch_plan.dart';
import '../../lunch_box/model/lunch_week.dart';
import '../../nanny_hub/data/shift_repository.dart';
import '../../nanny_hub/model/shift.dart';
import '../../nanny_hub/model/shift_summary.dart';
import '../../todos/data/todo_repository.dart';
import '../../todos/model/routine.dart';
import '../../todos/model/task.dart';
import '../../todos/model/task_completion.dart';
import '../model/load_sources.dart';

/// The reads the mental-load view is derived from — every one of them a
/// stream another feature's repository already offers, bounded to the
/// household and, where it grows, to the week (`BE-08`, calendar ADR-0006).
///
/// The carer shifts are read only when the viewer may see the nanny hub
/// ([includeCare]); otherwise they are simply empty, never a refused read.
/// The view is the family's, who read lunch and home care in full.
final class LoadListeners {
  LoadListeners({
    required CalendarRepository calendarRepository,
    required TodoRepository todoRepository,
    required GroceryRepository groceryRepository,
    required ShiftRepository shiftRepository,
    required LunchRepository lunchRepository,
    required CleaningJobRepository cleaningJobRepository,
    required this.householdId,
    required this.includeCare,
  }) : _calendar = calendarRepository,
       _todos = todoRepository,
       _groceries = groceryRepository,
       _shifts = shiftRepository,
       _lunch = lunchRepository,
       _jobs = cleaningJobRepository;

  final CalendarRepository _calendar;
  final TodoRepository _todos;
  final GroceryRepository _groceries;
  final ShiftRepository _shifts;
  final LunchRepository _lunch;
  final CleaningJobRepository _jobs;
  final String householdId;
  final bool includeCare;

  final List<StreamSubscription<Object?>> _whole = [];
  final List<StreamSubscription<Object?>> _windowed = [];
  void Function() _onChange = _nothing;
  void Function(AppFailure failure) _onError = _ignore;

  List<HouseholdEvent>? _events;
  List<EventException>? _exceptions;
  List<Task>? _tasks;
  List<Routine>? _routines;
  List<TaskCompletion>? _completions;
  List<GroceryItem>? _items;
  List<Shift>? _open;
  List<ShiftSummary>? _summaries;
  List<LunchPlan>? _plans;
  List<CleaningJob>? _cleaningJobs;

  /// Everything, once every read has answered at least once; null before.
  LoadSources? get sources {
    final events = _events, exceptions = _exceptions, tasks = _tasks;
    final routines = _routines, completions = _completions, items = _items;
    final open = _open, summaries = _summaries;
    final plans = _plans, jobs = _cleaningJobs;
    if (events == null ||
        exceptions == null ||
        tasks == null ||
        routines == null ||
        completions == null ||
        items == null ||
        open == null ||
        summaries == null ||
        plans == null ||
        jobs == null) {
      return null;
    }
    return LoadSources(
      events: events,
      exceptions: exceptions,
      tasks: tasks,
      routines: routines,
      completions: completions,
      groceries: items,
      openShifts: open,
      shiftSummaries: summaries,
      lunchPlans: plans,
      homeCareJobs: jobs,
    );
  }

  void open({
    required CalendarDate from,
    required CalendarDate to,
    required void Function() onChange,
    required void Function(AppFailure failure) onError,
  }) {
    _onChange = onChange;
    _onError = onError;
    _openWhole();
    _openWindow(from, to);
  }

  /// The week moved: only the three reads that follow it are reopened.
  Future<void> moveWindow({
    required CalendarDate from,
    required CalendarDate to,
  }) async {
    await _cancel(_windowed);
    _exceptions = null;
    _completions = null;
    _plans = null;
    _openWindow(from, to);
  }

  Future<void> reopen({
    required CalendarDate from,
    required CalendarDate to,
  }) async {
    await close();
    _events = _tasks = null;
    _routines = null;
    _items = null;
    _open = null;
    _summaries = null;
    _cleaningJobs = null;
    _exceptions = null;
    _completions = null;
    _plans = null;
    _openWhole();
    _openWindow(from, to);
  }

  Future<void> close() async {
    await _cancel(_whole);
    await _cancel(_windowed);
  }

  void _openWhole() {
    _whole
      ..add(_listen(_calendar.watchEvents(householdId), (v) => _events = v))
      ..add(_listen(_todos.watchTasks(householdId), (v) => _tasks = v))
      ..add(_listen(_todos.watchRoutines(householdId), (v) => _routines = v))
      ..add(_listen(_groceries.watchItems(householdId), (v) => _items = v))
      ..add(_listen(_jobs.watchJobs(householdId), (v) => _cleaningJobs = v));
    if (includeCare) {
      _whole
        ..add(_listen(_shifts.watchOpenShifts(householdId), (v) => _open = v))
        ..add(
          _listen(_shifts.watchSummaries(householdId), (v) => _summaries = v),
        );
    } else {
      _open = const [];
      _summaries = const [];
    }
  }

  void _openWindow(CalendarDate from, CalendarDate to) {
    _windowed
      ..add(
        _listen(
          _calendar.watchExceptions(householdId, from: from, to: to),
          (v) => _exceptions = v,
        ),
      )
      ..add(
        _listen(
          _todos.watchCompletions(householdId, from: from, to: to),
          (v) => _completions = v,
        ),
      )
      // The window is always one Monday-to-Sunday week — one lunch week.
      ..add(
        _listen(
          _lunch.watchPlans(
            householdId,
            from: LunchWeek.of(from),
            to: LunchWeek.of(from),
          ),
          (v) => _plans = v,
        ),
      );
  }

  StreamSubscription<Object?> _listen<T>(
    Stream<T> stream,
    void Function(T value) keep,
  ) => stream.listen(
    (value) {
      keep(value);
      _onChange();
    },
    onError: (Object error) =>
        _onError(error is AppFailure ? error : UnknownFailure(error)),
  );

  static Future<void> _cancel(List<StreamSubscription<Object?>> list) async {
    final cancelling = [for (final subscription in list) subscription.cancel()];
    list.clear();
    await Future.wait(cancelling);
  }

  static void _nothing() {}
  static void _ignore(AppFailure failure) {}
}
