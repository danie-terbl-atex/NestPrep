import 'package:nestprep/features/calendar/model/household_event.dart';
import 'package:nestprep/features/groceries/model/grocery_item.dart';
import 'package:nestprep/features/household/model/member.dart';
import 'package:nestprep/features/mental_load/state/load_listeners.dart';
import 'package:nestprep/features/mental_load/state/mental_load_controller.dart';
import 'package:nestprep/features/todos/model/task.dart';
import 'package:nestprep/features/todos/model/task_completion.dart';
import 'package:nestprep/shared/time/household_clock.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import 'fake_calendar_repository.dart';
import 'fake_calendar_v2.dart';
import 'fake_grocery_repository.dart';
import 'fake_home_care.dart';
import 'fake_lunch_repository.dart';
import 'fake_nanny_shifts.dart';
import 'fake_todo_repository.dart';
import 'household_fixtures.dart';
import 'mental_load_fixtures.dart';

/// The shared week's controller over the six features' fakes (calendar
/// ADR-0006), with a helper that answers every read at once.
final class MentalLoadHarness {
  MentalLoadHarness({this.includeCare = true, List<Member>? members}) {
    tz_data.initializeTimeZones();
    controller = MentalLoadController(
      loadListeners: LoadListeners(
        calendarRepository: calendar,
        todoRepository: todos,
        groceryRepository: groceries,
        shiftRepository: shifts,
        lunchRepository: lunches,
        cleaningJobRepository: jobs,
        householdId: Fixtures.householdId,
        includeCare: includeCare,
      ),
      cardImageSharer: sharer,
      householdClock: HouseholdClock(
        'Africa/Johannesburg',
        now: () => LoadFixtures.at(LoadFixtures.wednesday),
      ),
      householdMembers: members ?? LoadFixtures.members,
    );
  }

  final bool includeCare;
  final calendar = FakeCalendarRepository();
  final todos = FakeTodoRepository();
  final groceries = FakeGroceryRepository();
  final shifts = FakeShiftRepository();
  final lunches = FakeLunchRepository();
  final jobs = FakeCleaningJobRepository();
  final sharer = FakeCardImageSharer();
  late final MentalLoadController controller;

  /// Every read answers: [events], [tasks] with [completions], [groceries].
  void answer({
    List<HouseholdEvent> events = const [],
    List<Task> tasks = const [],
    List<TaskCompletion> completions = const [],
    List<GroceryItem> items = const [],
  }) {
    calendar
      ..emitEvents(events)
      ..emitExceptions(const []);
    todos
      ..emitTasks(tasks)
      ..emitRoutines(const [])
      ..emitCompletions(completions);
    groceries.emitItems(items);
    lunches.emitPlans(const []);
    jobs.emitJobs(const []);
    if (includeCare) {
      shifts.openShifts.add(const []);
      shifts.summaries.add(const []);
    }
  }

  /// A week with something for both parents in it.
  void answerABusyWeek() => answer(
    events: [
      LoadFixtures.event('e1', createdBy: Fixtures.samMemberId),
      LoadFixtures.event(
        'e2',
        createdBy: LoadFixtures.alexMemberId,
        memberIds: [Fixtures.samMemberId],
      ),
    ],
    tasks: [
      LoadFixtures.task('t1'),
      LoadFixtures.task('t2', assigneeIds: [LoadFixtures.alexMemberId]),
    ],
    completions: [LoadFixtures.done('t1', by: Fixtures.samMemberId)],
    items: [
      LoadFixtures.grocery(
        'g1',
        addedBy: LoadFixtures.alexMemberId,
        boughtBy: LoadFixtures.alexMemberId,
      ),
    ],
  );

  Future<void> close() async {
    controller.dispose();
    await calendar.close();
    await todos.close();
    await groceries.close();
    await shifts.close();
    await lunches.close();
    await jobs.close();
  }
}
