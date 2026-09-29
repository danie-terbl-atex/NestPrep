import '../../features/two_homes/model/change_request.dart';
import '../../features/two_homes/model/custody_schedule.dart';
import '../failure/app_failure.dart';

export 'two_homes_handover_copy.dart';
export 'two_homes_setup_copy.dart';

/// Every word the two-homes feature says (`FE-19`, household ADR-0004), in a
/// file of its own exported from `app_copy.dart`.
///
/// The tone is the whole design here: calm, warm and neutral. Two homes
/// that share a child may share little else, so nothing on these screens
/// says who is late, who refused or who is to blame. A request is *asked*
/// and *answered*; a home is named by the name it chose; the child comes
/// first in every sentence about them.
abstract final class TwoHomesCopy {
  static const title = 'Two homes';
  static const openFromHousehold = 'Two homes';
  static const openFromHouseholdBody =
      'A shared schedule and calm handovers with your child’s other home.';

  // The list.
  static const emptyTitle = 'One child, two homes';
  static const emptyBody =
      'If your child lives between two homes, link them here. Both homes see '
      'the same schedule and handover notes — and nothing else of each '
      'other’s.';
  static const linkAnotherHome = 'Link with another home';
  static const haveACode = 'I have a code';
  static const adminStartsNote =
      'An admin of this household links homes. Ask them to start.';
  static const linkedChildren = 'Linked children';
  static const pastLinks = 'Past links';
  static String withToday(String child, String home) =>
      '$child is with $home today';
  static String goesToday(String child, String home) =>
      '$child goes to $home today';
  static String nextHandover(String date, String home) =>
      'Next handover: $date, to $home';
  static const noHandoverSoon = 'No change of home in the next twelve weeks.';
  static String homesTogether(String a, String b) => '$a and $b';

  // Waiting to be linked.
  static String confirmQuestion(String otherHome, String child) =>
      '$otherHome accepted your code for $child. Is that who you expected?';
  static const confirmYes = 'Yes, link our homes';
  static const confirmNo = 'No, not them';
  static String waitingFor(String otherHome) =>
      'Waiting for $otherHome to confirm. Nothing is shared until they do.';
  static const statusEnded = 'Link ended';
  static const statusDeclined = 'Not linked';
  static const statusPending = 'Waiting to link';

  // One link.
  static const linkGone = 'That link is no longer here.';
  static const nextTwoWeeks = 'The next two weeks';
  static const comingHandovers = 'Coming handovers';
  static const noComingHandovers =
      'No change of home in the next twelve weeks.';
  static String handoverRow(String child, String home) =>
      '$child goes to $home';
  static String handoverAt(String time) => 'at $time';
  static const requests = 'Changes';
  static const waitingForAnswer = 'Waiting for an answer';
  static const history = 'Earlier';
  static const noRequests =
      'When either home asks to swap some days, it shows here for the other '
      'to answer.';
  static const askForASwap = 'Ask for a swap';
  static const suggestSchedule = 'Suggest a new schedule';
  static const endLink = 'End the link';
  static String endQuestion(String otherHome) =>
      'End the link with $otherHome?';
  static const endBody =
      'Nothing new will be shared. What was already shared stays with both '
      'homes, and you can link again with a new code.';
  static const endConfirm = 'End the link';
  static const endCancel = 'Keep it';
  static const scheduleOnly =
      'You can see the schedule. A parent can ask for changes and write '
      'handovers.';
  static const legendThisHome = 'This home';
  static String dayWith(String home) => 'with $home';

  // Asking and answering.
  static const swapTitle = 'Ask for a swap';
  static const swapFrom = 'From';
  static const swapUntil = 'Until';
  static const swapWith = 'With';
  static const noteLabel = 'A note for the other home';
  static const noteHint = 'Optional — a reason helps';
  static const send = 'Send';
  static String swapTooLong(int days) =>
      'A swap is up to $days days. For longer, suggest a new schedule.';
  static const swapEndsBeforeStart = 'Choose an end on or after the start.';
  static const scheduleRequestTitle = 'Suggest a new schedule';
  static const scheduleRequestBody =
      'The other home sees it and can accept it or keep the current one.';
  static String swapSummary(String child, String home, String dates) =>
      '$child with $home, $dates';
  static String dateSpan(String from, String to) =>
      from == to ? from : '$from – $to';
  static String scheduleSummary(CustodyPattern pattern) =>
      'A new schedule: ${patternName(pattern)}';
  static String askedBy(String home) => 'Asked by $home';
  static const accept = 'Accept';
  static const decline = 'Decline';
  static const withdraw = 'Withdraw';
  static String answeredNote(String home, String note) => '$home: “$note”';
  static String status(RequestStatus status) => switch (status) {
    RequestStatus.pending => 'Waiting',
    RequestStatus.accepted => 'Accepted',
    RequestStatus.declined => 'Declined',
    RequestStatus.withdrawn => 'Withdrawn',
    RequestStatus.closed => 'Closed',
  };

  // Schedules.
  static String patternName(CustodyPattern pattern) => switch (pattern) {
    CustodyPattern.alternatingWeeks => 'Alternating weeks',
    CustodyPattern.twoTwoThree => '2-2-3',
    CustodyPattern.everyOtherWeekend => 'Every other weekend',
    CustodyPattern.custom => 'Our own fortnight',
  };
  static String patternBody(CustodyPattern pattern) => switch (pattern) {
    CustodyPattern.alternatingWeeks => 'A week in each home.',
    CustodyPattern.twoTwoThree =>
      'Two days, two days, three days — never more than three apart.',
    CustodyPattern.everyOtherWeekend =>
      'Weekdays in one home, every other weekend in the other.',
    CustodyPattern.custom => 'Tap each day of two weeks to choose the home.',
  };
  static const startsOn = 'Starting the week of';
  static const firstWith = 'The first week starts with';
  static const weekdaysWith = 'Weekdays with';
  static const changesOn = 'Changes homes on';
  static const handoverTime = 'Handover time';
  static const anyTime = 'Any time that day';
  static const customHint = 'Tap a day to move it to the other home.';
  static const weekdayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  // The calendar.
  static String bandWith(String child, String home) => '$child · with $home';
  static String bandHandover(String child, String home) =>
      '$child goes to $home';
  static const bandFromTwoHomes = 'From Two homes';

  static String problem(CoParentProblem problem) => switch (problem) {
    CoParentProblem.notFamily =>
      'A parent in this household can do that. Ask one of them.',
    CoParentProblem.linkInviteNotFound =>
      'That code isn’t one we know. Check it with the other home.',
    CoParentProblem.linkInviteExpired =>
      'That code has expired. The other home can make a new one.',
    CoParentProblem.linkInviteUsed =>
      'That code has already been used. The other home can make a new one.',
    CoParentProblem.sameHousehold =>
      'That code was made in this household. It is for the other home.',
    CoParentProblem.childNotFound =>
      'That child isn’t in this household any more.',
    CoParentProblem.childAlreadyLinked =>
      'That child is already linked with another home.',
    CoParentProblem.linkNotFound => linkGone,
    CoParentProblem.linkNotActive =>
      'That link isn’t active, so nothing new can be shared.',
    CoParentProblem.notYourTurn => 'That one is for the other home to answer.',
    CoParentProblem.requestNotFound => 'That request is no longer here.',
    CoParentProblem.requestAlreadyAnswered =>
      'That request has already been answered.',
    CoParentProblem.tooManyRequests =>
      'There are already ten requests waiting. Answer or withdraw some first.',
    CoParentProblem.dateOutOfRange =>
      'That date is too far away. Choose one within the year.',
  };
}
