import 'dart:async';

import '../../../shared/failure/app_failure.dart';
import '../../../shared/time/calendar_date.dart';
import '../../accounts/model/kid_identity.dart';
import '../../household/model/member.dart';
import '../../lunch_box/data/lunch_repository.dart';
import '../../lunch_box/model/lunch_plan.dart';
import '../../lunch_box/model/lunch_week.dart';
import '../../meal_planning/data/meal_repository.dart';
import '../../meal_planning/model/meal.dart';
import '../../meal_planning/model/week_plan.dart';
import '../../todos/data/todo_repository.dart';
import '../../todos/model/routine.dart';
import '../../todos/model/task.dart';
import '../../todos/model/task_completion.dart';
import '../model/kid_areas.dart';
import '../model/kid_day.dart';

/// The parts of a kid's day a grant opens or closes on its own.
enum KidPart { chores, food, lunch }

/// The reads a kid device's grant opens, and only those (accounts ADR-0004):
/// its own chores — tasks, routines, completions — the day's food, and its
/// own lunch box (lunch-box ADR-0004).
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
    required LunchRepository lunchRepository,
    required this.identity,
    required this.onChange,
    required this.onFailure,
  }) : _todos = todoRepository,
       _meals = mealRepository,
       _lunches = lunchRepository;

  final TodoRepository _todos;
  final MealRepository _meals;
  final LunchRepository _lunches;
  final KidIdentity identity;

  /// Something arrived, or a part opened or closed.
  final void Function() onChange;

  /// A failure that is not a refusal: an error the kid can retry.
  final void Function(AppFailure failure) onFailure;

  final _chores = <StreamSubscription<Object?>>[];
  final _food = <StreamSubscription<Object?>>[];
  final _lunch = <StreamSubscription<Object?>>[];
  KidAreas? _wanted;
  KidAreas? _opened;
  CalendarDate? _today;

  List<Task>? tasks;
  List<Routine>? routines;
  List<TaskCompletion>? completions;
  WeekPlan? plan;
  List<Meal>? library;

  /// This kid's plan for this week — only ever the one document the `own`
  /// grant opens.
  LunchPlan? lunchPlan;

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
    final lunchPlan = this.lunchPlan;
    if (areas == null ||
        tasks == null ||
        routines == null ||
        completions == null ||
        plan == null ||
        library == null ||
        lunchPlan == null) {
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
      lunchPlan: lunchPlan,
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
    final open = [..._chores, ..._food, ..._lunch];
    _chores.clear();
    _food.clear();
    _lunch.clear();
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
    if (opened?.lunch != areas.lunch) {
      _drop(_lunch);
      final week = LunchWeek.of(today);
      if (areas.lunch) {
        lunchPlan = null;
        _openLunch(week);
      } else {
        lunchPlan = LunchPlan.empty(childId: identity.memberId, week: week);
      }
    }
  }

  void _openLunch(LunchWeek week) {
    final id = identity;
    _listen(
      _lunch,
      () => _closeRefused(KidPart.lunch),
      _lunches.watchPlan(id.householdId, childId: id.memberId, week: week),
      (value) => lunchPlan = value,
    );
  }

  void _openChores(CalendarDate today) {
    final id = identity;
    void refused() => _closeRefused(KidPart.chores);
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
    void refused() => _closeRefused(KidPart.food);
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

  void _closeRefused(KidPart part) {
    final (opened, today) = (_opened, _today);
    if (opened == null || today == null) return;
    // Forget what was wanted, so the profile's next emission — even the same
    // grant — reopens exactly what it allows.
    _wanted = null;
    _apply(
      KidAreas(
        chores: part != KidPart.chores && opened.chores,
        canTick: part != KidPart.chores && opened.canTick,
        food: part != KidPart.food && opened.food,
        lunch: part != KidPart.lunch && opened.lunch,
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
