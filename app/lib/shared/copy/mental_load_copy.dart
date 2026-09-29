import '../../features/mental_load/model/week_load.dart';
import '../failure/app_failure.dart';

/// Every word the mental-load view says (`FE-19`, calendar ADR-0006). Warm
/// and never a scoreboard: it notices what each adult carried, it does not
/// rank them, and it says out loud that the invisible work counts too.
abstract final class MentalLoadCopy {
  static const title = 'This week, shared';
  static const openFromHousehold = 'This week, shared';
  static const openFromHouseholdBody =
      'Who picked up what — the plans, the to-dos, the shopping.';
  static const intro =
      'Everything that kept the house running, and who picked it up. '
      'Not a score — a way to see the week together.';
  static const previousWeek = 'Previous week';
  static const nextWeek = 'Next week';
  static const thisWeek = 'This week';
  static const splitLabel = 'How the week was shared';
  static const emptyTitle = 'A quiet week so far';
  static const emptyBody =
      'As events, to-dos and groceries are added and ticked, you will see '
      'who picked up what.';
  static const footnote =
      'Counted from what is in NestPrep. The remembering and the '
      'thinking-ahead count too, even when nobody wrote them down.';
  static const share = 'Share';
  static String shareLabel(String name) => 'Share $name’s week as a picture';
  static const noAdultsTitle = 'Nobody to share the week with yet';
  static const noAdultsBody =
      'Once another parent joins the household, you will see how the week '
      'is shared between you.';

  static String carried(String name, int count) => switch (count) {
    0 => 'A lighter week for $name — that is allowed.',
    1 => '$name picked up 1 thing',
    _ => '$name picked up $count things',
  };

  static String splitPart(String name, int count) => '$name, $count';

  static String kind(LoadKind kind, int count) => switch (kind) {
    LoadKind.eventsPlanned => count == 1 ? 'event planned' : 'events planned',
    LoadKind.eventsAttended =>
      count == 1 ? 'event to be at' : 'events to be at',
    LoadKind.todosDone => count == 1 ? 'to-do done' : 'to-dos done',
    LoadKind.todosWaiting =>
      count == 1 ? 'to-do on their list' : 'to-dos on their list',
    LoadKind.groceriesBought =>
      count == 1 ? 'grocery bought' : 'groceries bought',
    LoadKind.groceriesAdded =>
      count == 1 ? 'grocery added to the list' : 'groceries added to the list',
    LoadKind.careShifts =>
      count == 1 ? 'carer shift handed over' : 'carer shifts handed over',
  };

  static String including(String highlights) => 'Including $highlights';

  static String shareText(String name, String week) =>
      '$name’s week in our house, $week — from NestPrep.';

  static String problem(MentalLoadProblem problem) => switch (problem) {
    MentalLoadProblem.cardUnreadable =>
      'That card could not be turned into a picture. Please try again.',
    MentalLoadProblem.shareUnavailable =>
      'Sharing would not open on this phone.',
  };
}
