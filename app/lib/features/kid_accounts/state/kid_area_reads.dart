import 'dart:async';

import '../../../shared/failure/app_failure.dart';
import '../../../shared/time/calendar_date.dart';
import '../../accounts/model/kid_identity.dart';
import '../../household/model/member.dart';
import '../../meal_planning/data/meal_repository.dart';
import '../../meal_planning/model/meal.dart';
import '../../meal_planning/model/week_plan.dart';
import '../../todos/data/todo_repository.dart';
import '../../todos/model/routine.dart';
import '../../todos/model/task.dart';
import '../../todos/model/task_completion.dart';
import '../model/kid_areas.dart';
import '../model/kid_day.dart';

/// The reads a kid device's grant opens, and only those (accounts ADR-0004):
/// its own chores — tasks, routines, completions — and the day's food.
///
/// [want] is told what the kid profile's grant allows every time the profile
/// emits; [start] is told the household's today once. Between them the open
/// listeners move to match, touching only the part that changed, so a grant
/// emitted again unchanged moves nothing and a change to ticking alone moves
/// no read.
///
/// A read the rules refuse here is not a signed-out device — the household
/// and the profile say that. It is a grant that narrowed a moment before the
/// profile did: that part is closed until the profile's next emission.
final class KidAreaReads {
  KidAreaReads({
    required TodoRepository todoRepository,
    required MealRepository mealRepository,
    required this.identity,
    required this.onChange,
    required this.onFailure,
  }) : _todos = todoRepository,
       _meals = mealRepository;

  final TodoRepository _todos;
  final MealRepository _meals;
  final KidIdentity identity;

  /// Something arrived, or a part opened or closed.
  final void Function() onChange;

  /// A failure that is not a refusal: an error the kid can retry.
  final void Function(AppFailure failure) onFailure;

  final _chores = <StreamSubscription<Object?>>[];
  final _food = <StreamSubscription<Object?>>[];
  KidAreas? _wanted;
  KidAreas? _opened;
  CalendarDate? _today;

  List<Task>? tasks;
  List<Routine>? routines;
  List<TaskCompletion>? completions;
  WeekPlan? plan;
  List<Meal>? library;

  /// What the open reads reflect — null until both [want] and [start] have
  /// been told.
  KidAreas? get opened => _opened;

  /// The day as far as these reads go, once every part it shows has
  /// arrived; null until then.
  KidDay? dayFor(Member me, CalendarDate today) {
    final (areas, tasks, routines) = (_opened, this.tasks, this.routines);
    final (completions, plan, library) = (
      this.completions,
      this.plan,
      this.library,
    );
    if (areas == null ||
        tasks == null ||
        routines == null ||
        completions == null ||
        plan == null ||
        library == null) {
      return null;
    }
    return KidDay.from(
      me: me,
      today: today,
      areas: areas,
      tasks: tasks,
      routines: routines,
      completions: completions,
      plan: plan,
      library: library,
    );
  }

  void want(KidAreas areas) {
    if (areas == _wanted) return;
    _wanted = areas;
    final today = _today;
    if (today != null) _apply(areas, today);
  }

  void start(CalendarDate today) {
    if (_today != null) return;
    _today = today;
    final wanted = _wanted;
    if (wanted != null) _apply(wanted, today);
  }

  Future<void> close() async {
    final open = [..._chores, ..._food];
    _chores.clear();
    _food.clear();
    for (final subscription in open) {
      await subscription.cancel();
    }
  }

  void _apply(KidAreas areas, CalendarDate today) {
    final opened = _opened;
    _opened = areas;
    if (opened?.chores != areas.chores) {
      _drop(_chores);
      if (areas.chores) {
        tasks = null;
        routines = null;
        completions = null;
        _openChores(today);
      } else {
        tasks = const <Task>[];
        routines = const <Routine>[];
        completions = const <TaskCompletion>[];
      }
    }
    if (opened?.food != areas.food) {
      _drop(_food);
      if (areas.food) {
        plan = null;
        library = null;
        _openFood(today);
      } else {
        plan = WeekPlan.empty(today.weekStart);
        library = const <Meal>[];
      }
    }
  }

  void _openChores(CalendarDate today) {
    final id = identity;
    void refused() => _closeRefused(chores: true);
    _listen(
      _chores,
      refused,
      _todos.watchTasksFor(id.householdId, id.memberId),
      (value) {
        tasks = value;
      },
    );
    _listen(_chores, refused, _todos.watchRoutines(id.householdId), (value) {
      routines = value;
    });
    _listen(
      _chores,
      refused,
      _todos.watchCompletionsFor(
        id.householdId,
        id.memberId,
        from: KidDay.windowStartFor(today),
        to: today,
      ),
      (value) => completions = value,
    );
  }

  void _openFood(CalendarDate today) {
    final id = identity;
    void refused() => _closeRefused(chores: false);
    _listen(_food, refused, _meals.watchWeek(id.householdId, today.weekStart), (
      value,
    ) {
      plan = value;
    });
    _listen(_food, refused, _meals.watchMeals(id.householdId), (value) {
      library = value;
    });
  }

  void _listen<T>(
    List<StreamSubscription<Object?>> into,
    void Function() onRefused,
    Stream<T> stream,
    void Function(T value) onValue,
  ) {
    into.add(
      stream.listen(
        (value) {
          onValue(value);
          onChange();
        },
        onError: (Object error) {
          final failure = error is AppFailure ? error : UnknownFailure(error);
          if (failure is PermissionDeniedFailure) return onRefused();
          onFailure(failure);
        },
      ),
    );
  }

  void _closeRefused({required bool chores}) {
    final (opened, today) = (_opened, _today);
    if (opened == null || today == null) return;
    // Forget what was wanted, so the profile's next emission — even the same
    // grant — reopens exactly what it allows.
    _wanted = null;
    _apply(
      KidAreas(
        chores: !chores && opened.chores,
        canTick: !chores && opened.canTick,
        food: chores && opened.food,
      ),
      today,
    );
    onChange();
  }

  void _drop(List<StreamSubscription<Object?>> subscriptions) {
    final open = [...subscriptions];
    subscriptions.clear();
    for (final subscription in open) {
      unawaited(subscription.cancel());
    }
  }
}
