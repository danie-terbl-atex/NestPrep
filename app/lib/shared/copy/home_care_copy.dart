import '../../features/home_care/model/home_care_board.dart';
import '../../features/home_care/model/job_details.dart';
import '../../features/home_care/model/job_status.dart';
import '../failure/app_failure.dart';

// The rooms and products, and the safety words, each have a file of their
// own, reached through this one (home-care ADR-0002).
export 'home_care_library_copy.dart';
export 'home_care_safety_copy.dart';

/// Every word the home-care job screens say (`FE-19`) — exported from
/// `app_copy.dart`, so a feature this size does not grow the one copy file,
/// and parallel features do not edit the same lines.
abstract final class HomeCareCopy {
  static const title = 'Home care';
  static const yourJobs = 'Your cleaning jobs';
  static const subtitle = 'Jobs for the house, with what to use and how';
  static const helperSubtitle = 'What to clean, with what, and how';
  static const openFromHousehold = 'Home care';
  static const openFromHouseholdBody =
      'Cleaning jobs with the right products, steps and safety.';
  static const openFromHouseholdHelperBody =
      'The cleaning jobs assigned to you.';
  static const newJob = 'New job';

  static String status(JobStatus status) => switch (status) {
    JobStatus.assigned => 'New',
    JobStatus.inProgress => 'Started',
    JobStatus.submitted => 'Handed in',
    JobStatus.approved => 'Approved',
    JobStatus.sentBack => 'Sent back',
  };

  static String due(String day) => 'Due $day';
  static String overdue(String day) => 'Late · was due $day';
  static String whereAndWho(String where, String who) => '$where · $who';
  static const roomGone = 'A room that was removed';
  static const helperGone = 'Somebody who has left';

  static String stepsDone(int done, int total) =>
      total == 1 ? '$done of 1 step' : '$done of $total steps';

  static String pileWithCount(JobPile pile, int count) =>
      '${_pileName(pile)} · $count';

  static String _pileName(JobPile pile) => switch (pile) {
    JobPile.toDo => 'To do',
    JobPile.toReview => 'To review',
    JobPile.done => 'Done',
  };

  static String emptyTitle(JobPile pile, {required bool isHelper}) =>
      switch (pile) {
        JobPile.toDo when isHelper => 'Nothing for you right now',
        JobPile.toDo => 'Nothing to clean',
        JobPile.toReview => 'Nothing waiting',
        JobPile.done => 'Nothing finished yet',
      };

  static String emptyBody(JobPile pile, {required bool isHelper}) =>
      switch (pile) {
        JobPile.toDo when isHelper =>
          'A job appears here when it is assigned to you.',
        JobPile.toDo =>
          'Photograph a spot, circle it, and send it to your helper with '
              'New job.',
        JobPile.toReview when isHelper =>
          'Jobs you hand in wait here until a parent has looked.',
        JobPile.toReview =>
          'A job handed in with its after photo waits here for you.',
        JobPile.done => 'Approved jobs are kept here.',
      };

  static String problem(HomeCareProblem problem) => switch (problem) {
    HomeCareProblem.cameraRefused =>
      'NestPrep needs the camera or your photos for this. Allow them in your '
          'phone settings.',
    HomeCareProblem.photoUnreadable =>
      'That picture could not be read. Try another photo.',
    HomeCareProblem.photoTooLarge =>
      'That photo is too big, even made smaller. Try taking it again.',
    HomeCareProblem.stepsNotDone =>
      'Tick every step before you hand the job in.',
  };

  static String missing(JobDetailsProblem problem) => switch (problem) {
    JobDetailsProblem.noTitle => 'Say what needs doing.',
    JobDetailsProblem.noRoom => 'Choose the room.',
    JobDetailsProblem.noHelper => 'Choose who will do it.',
    JobDetailsProblem.noSteps => 'Add at least one step.',
  };

  static const beforePrompt = 'Photograph the spot';
  static const beforePromptBody =
      'Take a photo of what needs cleaning. You can circle the exact spot '
      'next.';
  static const afterPrompt = 'Show it is clean';
  static const afterPromptBody =
      'Take a photo of the same spot now, so it can be checked.';
  static const beforePhoto = 'The spot before cleaning';
  static const afterPhoto = 'The spot after cleaning';
  static const before = 'Before';
  static const after = 'After';
  static const takePhoto = 'Take a photo';
  static const retakePhoto = 'Take it again';
  static const choosePhoto = 'Choose from phone';
  static const photoMissing = 'Add a photo of the spot first.';

  static const markSpot = 'Circle the spot';
  static const markAgain = 'Change the circles';
  static const markTitle = 'Circle the spot';
  static const markHint = 'Draw round it with your finger';
  static const markCancel = 'Cancel';
  static const markUndo = 'Undo the last circle';
  static const markClear = 'Clear every circle';
  static const markDone = 'Done';
  static String markSurface(int count) => count == 0
      ? 'The photo. Draw on it to circle the spot.'
      : 'The photo, with $count ${count == 1 ? 'circle' : 'circles'} on it.';

  static const jobTitle = 'What needs doing';
  static const jobTitleHint = 'Like “Grease on the oven door”';
  static const room = 'Room';
  static const helper = 'Who will do it';
  static const dueDate = 'Done by';
  static const productsToUse = 'Products to use';
  static const steps = 'Steps';
  static const jobNote = 'Anything else';
  static const jobNoteHint = 'A tip, or something to be careful of';
  static const addStep = 'Add a step';
  static const addStepHint = 'Like “Rinse with warm water”';
  static String removeStep(String step) => 'Remove “$step”';

  /// Steps most jobs need, offered as one tap each.
  static const suggestedSteps = [
    'Open a window',
    'Put on gloves',
    'Test on a hidden spot first',
    'Leave it for five minutes',
    'Rinse with clean water',
    'Dry with a clean cloth',
    'Put the products back',
  ];

  static const assign = 'Assign the job';
  static const jobTitleScreen = 'Cleaning job';
  static String sentBackWith(String note) => 'Sent back: “$note”';
  static const start = 'Start the job';
  static const carryOn = 'Carry on';
  static const tryAgain = 'Do it again';
  static const review = 'Review the job';
  static const waitingForReview =
      'Handed in. A parent will look at it and approve it or send it back.';
  static const editJob = 'Change the job';
  static const deleteJob = 'Delete the job';
  static const deleteJobConfirm = 'Delete this job?';
  static const deleteJobBody =
      'The job, its photos and its history go for good.';
  static const noProductsOnJob = 'No products chosen for this job.';

  static const history = 'History';
  static const historyEmpty = 'Nothing has happened to this job yet.';
  static String byWhom(String who) => 'By $who';
  static const justNow = 'Just now';
  static String dayAndTime(String day, String time) => '$day, $time';
  static String quoted(String text) => '“$text”';

  static const jobGoneTitle = 'This job is no longer here';
  static const jobGoneBody =
      'It was deleted. Go back to see the jobs there are.';

  static const stepThroughTitle = 'Work through it';
  static const handIn = 'Hand it in';
  static const tickEveryStep = 'Tick every step, then take the after photo.';
  static String stepForReader(
    int number,
    String step, {
    required bool isDone,
  }) => 'Step $number: $step. ${isDone ? 'Done' : 'Not done yet'}.';

  static const reviewTitle = 'Review';
  static String handedInBy(String who) => 'Handed in by $who';
  static const approve = 'Approve';
  static const sendBack = 'Send it back';
  static const sendBackTitle = 'What still needs doing?';
  static const sendBackNote = 'A note for the helper';
  static const sendBackHint = 'Like “The corner by the tap is still marked”';
  static const nothingToReview = 'This job is not waiting for a review.';
}
