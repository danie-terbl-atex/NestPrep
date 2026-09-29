import '../../features/home_care/model/room_kind.dart';
import '../../features/home_care/model/routine/routine_cadence.dart';
import '../../features/home_care/model/routine/routine_draft.dart';

/// Every word the room routines say (home-care ADR-0004, `FE-19`) —
/// exported through `home_care_copy.dart`.
abstract final class HomeCareRoutineCopy {
  static const routines = 'Room routines';
  static const routinesSubtitle = 'Daily, weekly and deep cleans, room by room';
  static const today = 'Today’s rooms';
  static const todayBanner = 'What to clean in each room today';
  static const todayHeading = 'Today';
  static const openToday = 'Open today’s rooms';
  static const everyRoutineHeading = 'Every routine';

  static const newRoutine = 'New routine';
  static const editRoutine = 'Change the routine';
  static const routineName = 'Name';
  static const routineNameHint = 'Kitchen, every weekday';
  static const room = 'Room';
  static const helper = 'Who does it';
  static const cadence = 'How often';
  static const startsOn = 'Starts on';
  static const items = 'What to do';
  static const addItem = 'Add a thing to do';
  static const addItemHint = 'Like “Wipe the counters”';
  static const deleteRoutine = 'Delete routine';
  static const deleteConfirm = 'Delete this routine?';
  static const deleteBody =
      'Nothing more is added to anybody’s day. What was ticked before stays '
      'in the history.';

  static String cadenceName(RoutineCadence cadence) => switch (cadence) {
    RoutineCadence.daily => 'Daily',
    RoutineCadence.weekly => 'Weekly',
    RoutineCadence.deepClean => 'Deep clean',
  };

  static String missing(RoutineDraftProblem problem) => switch (problem) {
    RoutineDraftProblem.noName => 'Give the routine a name.',
    RoutineDraftProblem.noRoom => 'Choose the room.',
    RoutineDraftProblem.noHelper => 'Choose who will do it.',
    RoutineDraftProblem.noItems => 'Add at least one thing to do.',
  };

  /// One line under a routine: how often, who, and how much.
  static String summary(
    String cadence,
    String schedule,
    String who,
    int items,
  ) => '$cadence · $schedule · $who · ${thingsToDo(items)}';

  static String thingsToDo(int count) =>
      count == 1 ? '1 thing to do' : '$count things to do';

  static String done(int done, int total) =>
      total == 1 ? '$done of 1 done' : '$done of $total done';

  static const roomDone = 'All done';
  static const allRoomsDone = 'Every room is done for today. Thank you!';
  static const weekHeading = 'This week';

  /// One day of the week strip: its name, and how much of it was ticked.
  static String dayProgress(
    String weekday,
    int done,
    int due, {
    required bool isToday,
  }) {
    final day = isToday ? '$weekday (today)' : weekday;
    return due == 0 ? '$day · nothing' : '$day · $done of $due';
  }

  static const roomGone = 'A room that was removed';
  static const helperGone = 'Somebody who has left';
  static String forHelper(String name) => 'For $name';
  static String routineAndWho(String routine, String who) => '$routine · $who';

  static String itemForReader(
    String routine,
    String item, {
    required bool isDone,
  }) => '$routine: $item, ${isDone ? 'done' : 'not done yet'}';

  static const emptyTitle = 'No routines yet';
  static const emptyBody =
      'A routine is a checklist for one room that comes round by itself — the '
      'kitchen every weekday, the bathrooms on Fridays, a deep clean once a '
      'month.';
  static const emptyHelperBody =
      'When the family sets up routines for you, they show here.';
  static const noRoomsTitle = 'Add your rooms first';
  static const noRoomsBody =
      'A routine belongs to a room. Add the rooms of your home, then come back.';
  static const addRooms = 'Add rooms';
  static const nothingTodayTitle = 'Nothing on today';
  static const nothingTodayBody =
      'No room routine falls today. Enjoy the quiet.';

  /// A few things most homes do in a room like this, one tap each.
  static List<String> suggestedItems(RoomKind? kind, RoutineCadence cadence) =>
      switch ((kind, cadence)) {
        (RoomKind.kitchen, RoutineCadence.deepClean) => const [
          'Clean inside the oven',
          'Wipe out the fridge',
          'Degrease the extractor',
          'Wash the bins',
        ],
        (RoomKind.kitchen, _) => const [
          'Wash the dishes',
          'Wipe the counters',
          'Sweep the floor',
          'Mop the floor',
          'Empty the bin',
        ],
        (RoomKind.bathroom, RoutineCadence.deepClean) => const [
          'Scrub the grout',
          'Descale the taps and shower head',
          'Wash the shower curtain',
        ],
        (RoomKind.bathroom, _) => const [
          'Clean the toilet',
          'Wipe the basin',
          'Clean the mirror',
          'Wipe the bath or shower',
          'Mop the floor',
        ],
        (RoomKind.bedroom || RoomKind.kidsRoom, _) => const [
          'Make the beds',
          'Pack away the toys',
          'Dust the surfaces',
          'Vacuum the floor',
          'Change the sheets',
        ],
        (RoomKind.laundry, _) => const [
          'Wash a load',
          'Hang the washing',
          'Iron',
          'Fold and pack away',
        ],
        (_, RoutineCadence.deepClean) => const [
          'Wash the windows',
          'Dust the skirting boards',
          'Clean behind the furniture',
        ],
        _ => const [
          'Dust the surfaces',
          'Vacuum the floor',
          'Mop the floor',
          'Tidy away',
        ],
      };
}
