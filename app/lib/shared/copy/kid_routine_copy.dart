import '../../features/kid_routines/model/kid_routine_draft.dart';
import '../../features/kid_routines/model/kid_routine_slot.dart';
import '../../features/kid_routines/model/kid_routine_starter.dart';
import 'app_copy.dart';

/// Every word the children's routines say (kid-routines ADR-0001, `FE-19`).
abstract final class KidRoutineCopy {
  static const title = 'Routines';
  static const subtitle = 'Morning, afternoon and bedtime, in pictures';
  static const wayInTitle = 'Routines';
  static const wayInBody =
      'A morning, afternoon and bedtime run for each child';

  static const noKidsTitle = 'Add a child first';
  static const noKidsBody =
      'Routines belong to a child. Add yours under More, then come back.';

  static String slotName(KidRoutineSlot slot) => switch (slot) {
    KidRoutineSlot.morning => 'Morning',
    KidRoutineSlot.afternoon => 'Afternoon',
    KidRoutineSlot.bedtime => 'Bedtime',
  };

  static String setUp(KidRoutineSlot slot) => switch (slot) {
    KidRoutineSlot.morning => 'Set up a morning routine',
    KidRoutineSlot.afternoon => 'Set up an afternoon routine',
    KidRoutineSlot.bedtime => 'Set up a bedtime routine',
  };

  static String setUpFor(KidRoutineSlot slot, String kid) =>
      '${setUp(slot)} for $kid';

  static const addAnother = 'Add another';
  static String addAnotherFor(KidRoutineSlot slot, String kid) =>
      'Add another ${slotName(slot).toLowerCase()} routine for $kid';

  static const newRoutine = 'New routine';
  static const editRoutine = 'Change the routine';
  static const name = 'Name';
  static const slot = 'Part of the day';
  static const kids = 'Who it is for';
  static const days = 'Which days';
  static const schoolDays = 'School days';
  static const everyDay = 'Every day';
  static const weekends = 'Weekends';
  static const finishBy = 'Finish by';
  static const finishByNone = 'No time set';
  static const finishByClear = 'Clear the time';
  static const stars = 'Stars for finishing';
  static const steps = 'Steps';
  static const stepsHelp =
      'In the order they happen. Hold and drag to move one.';
  static const addStep = 'Add a step';
  static const moveStep = 'Move';
  static const suggestedSteps = 'Quick adds';
  static const makeCopy = 'Make a copy';
  static const deleteRoutine = 'Delete routine';
  static const deleteConfirm = 'Delete this routine?';
  static const deleteBody =
      'It comes off every child’s day. Stars already earned stay.';

  static String copyName(String name) => '$name (copy)';

  static String missing(KidRoutineDraftProblem problem) => switch (problem) {
    KidRoutineDraftProblem.noName => 'Give the routine a name.',
    KidRoutineDraftProblem.noKids => 'Choose who it is for.',
    KidRoutineDraftProblem.noDays => 'Choose at least one day.',
    KidRoutineDraftProblem.noSteps => 'Add at least one step.',
  };

  static String daysSummary(Set<int> weekdays) {
    if (weekdays.length == 7) return everyDay;
    if (_same(weekdays, KidRoutineDraft.schoolDays)) return schoolDays;
    if (_same(weekdays, KidRoutineDraft.weekend)) return weekends;
    return (weekdays.toList()..sort()).map(AppCopy.weekdayName).join(', ');
  }

  static bool _same(Set<int> a, Set<int> b) =>
      a.length == b.length && a.containsAll(b);

  static String stepCount(int count) => count == 1 ? '1 step' : '$count steps';

  static String by(String time) => 'by $time';

  static String sharedWith(List<String> names) => 'With ${names.join(', ')}';

  static const newStep = 'New step';
  static const editStep = 'Change the step';
  static const stepTitle = 'What to do';
  static const stepTitleHint = 'Like “Brush teeth”';
  static const stepTitleMissing = 'Say what to do.';
  static const stepNote = 'A note (optional)';
  static const stepNoteHint = 'Like “Top and bottom, two minutes”';
  static const packList = 'Things to remember';
  static const packListHelp =
      'What goes in the bag, or what to take along. Tap one to choose its '
      'days or a picture.';
  static const addPart = 'Add a thing';
  static const addPartHint = 'Like “Swimming kit”';
  static const partDays = 'Only on these days';
  static const partPicture = 'Picture';
  static const partPictureChange = 'Change picture';
  static const stepDone = 'Done';
  static const removeStep = 'Remove step';

  static String removePart(String text) => 'Remove $text';

  static String partsCount(int count) =>
      count == 1 ? '1 thing to remember' : '$count things to remember';

  static String partDaysSummary(List<int> weekdays) => weekdays.isEmpty
      ? everyDay
      : (weekdays.toList()..sort()).map(AppCopy.weekdayName).join(', ');

  // ---- the child's side ----

  static const kidTitle = 'Routines';
  static const kidStart = 'Start';
  static const kidKeepGoing = 'Keep going';
  static const kidAllDone = 'All done';
  static const kidLook = 'Have a look';
  static const kidStepDone = 'Done!';
  static const kidStepIsDone = 'Done';
  static const kidStepUndo = 'Not done yet';
  static const kidRemember = 'Remember';
  static const kidClose = 'Close';
  static const kidGoneTitle = 'This routine is not on today';
  static const kidGoneBody = 'Go back to see what is.';

  static String kidProgress(int done, int total) => '$done of $total done';

  static String kidStepOf(int number, int total) => 'Step $number of $total';

  static String kidNext(String title) => 'Next: $title';

  static String kidStepLabel(String title, {required bool isDone}) =>
      isDone ? '$title, done' : title;

  static const switchedOffTitle = 'Routines are not switched on yet';
  static const switchedOffBody = 'Nothing is lost. Check back soon.';

  /// The steps a new routine starts with — every one has a sticker in the
  /// library, which `kid_routine_starters_test` holds.
  static List<KidRoutineStarter> starters(KidRoutineSlot slot) =>
      switch (slot) {
        KidRoutineSlot.morning => const [
          KidRoutineStarter('Wake up', 'wake-up-alarm'),
          KidRoutineStarter('Get dressed', 'get-dressed'),
          KidRoutineStarter('Eat breakfast', 'eat-breakfast'),
          KidRoutineStarter('Brush teeth', 'brush-teeth'),
          KidRoutineStarter('Pack school bag', 'pack-school-bag'),
          KidRoutineStarter('Shoes on', 'put-on-shoes'),
        ],
        KidRoutineSlot.afternoon => const [
          KidRoutineStarter('Empty lunchbox', 'empty-lunchbox'),
          KidRoutineStarter('Have a snack', 'healthy-snack'),
          KidRoutineStarter('Homework', 'do-homework'),
          KidRoutineStarter('Play outside', 'play-outside'),
          KidRoutineStarter('Tidy toys', 'tidy-toys'),
        ],
        KidRoutineSlot.bedtime => const [
          KidRoutineStarter('Bath time', 'take-bath'),
          KidRoutineStarter('Pyjamas on', 'put-on-pyjamas'),
          KidRoutineStarter('Brush teeth', 'brush-teeth'),
          KidRoutineStarter('Story time', 'bedtime-story'),
          KidRoutineStarter('Lights off', 'lights-off'),
        ],
      };

  /// More steps offered as one tap each, beside the starters not in use.
  static List<KidRoutineStarter> extras(KidRoutineSlot slot) => switch (slot) {
    KidRoutineSlot.morning => const [
      KidRoutineStarter('Make bed', 'make-bed'),
      KidRoutineStarter('Wash face', 'wash-face'),
      KidRoutineStarter('Brush hair', 'brush-hair'),
      KidRoutineStarter('Pack lunchbox', 'pack-lunchbox'),
      KidRoutineStarter('Fill water bottle', 'fill-water-bottle'),
      KidRoutineStarter('Sunscreen on', 'put-on-sunscreen'),
    ],
    KidRoutineSlot.afternoon => const [
      KidRoutineStarter('Wash hands', 'wash-hands'),
      KidRoutineStarter('Reading time', 'reading-time'),
      KidRoutineStarter('Uniform ready', 'school-uniform-ready'),
      KidRoutineStarter('Pack school bag', 'pack-school-bag'),
      KidRoutineStarter('Drink water', 'drink-water'),
    ],
    KidRoutineSlot.bedtime => const [
      KidRoutineStarter('Tidy toys', 'tidy-toys'),
      KidRoutineStarter('Lay out clothes', 'lay-out-clothes'),
      KidRoutineStarter('Potty time', 'potty-time'),
      KidRoutineStarter('Wash face', 'wash-face'),
      KidRoutineStarter('Say goodnight', 'say-goodnight'),
    ],
  };
}
