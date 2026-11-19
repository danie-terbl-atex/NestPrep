import '../../features/calendar_sync/model/calendar_provider.dart';
import 'calendar_sync_copy.dart';

/// The creator's way in, five steps and a payoff (onboarding ADR-0001), and
/// what Twig says on each (design-system ADR-0026).
abstract final class OnboardingCopy {
  static const twigHello =
      'Hi, I’m Twig! Let’s build your family’s nest. It takes about a minute.';
  static const twigPromises =
      'Two quick promises first, then we build your nest.';
  static const twigHousehold =
      'Every nest needs a name. What does your family call home?';
  static const twigInvited = 'Hi, I’m Twig! Your family saved you a spot.';
  static const twigJoin = 'Nearly there. One tap and you’re in.';
  static const twigFamily = 'Who shares the nest? Add your kids first.';
  static String twigFamilyAdded(String name) =>
      '$name is in the nest. Anyone else?';
  static const twigCalendar =
      'Bring your calendar in and your week is waiting when you land.';
  static const twigCalendarWaiting =
      'Finish in your browser, then pop back here.';
  static String twigCalendarIn(CalendarProvider provider) =>
      'Got it! ${CalendarSyncCopy.providerName(provider)} is in.';
  static const twigReady = 'All done. Welcome home!';

  static const next = 'Next';
  static const skip = 'Skip for now';

  static const familyTitle = 'Who lives in your nest?';
  static const familyBody =
      'Children don’t need a phone: add them for lunches, chores and '
      'birthdays. Invite the grown-ups who share the load.';
  static const familyChildren = 'Children';
  static const familyAddChild = 'Add a child';
  static const familyAddChildBlurb = 'No phone needed';
  static const familyInvite = 'Invite someone';

  static const calendarTitle = 'Bring your calendar';
  static const calendarBody =
      'Connect the calendar you already use, and your family’s plans are '
      'here from the first day.';
  static const calendarConnected = 'Connected';
  static const calendarNext = 'Continue';

  static const readyTitle = 'Your nest is ready';
  static String readyPeople(int count) => switch (count) {
    0 => 'Just you for now. Invite anyone, any time, from People.',
    1 => '1 more person in your nest',
    _ => '$count more people in your nest',
  };
  static String readyCalendars(int count) => switch (count) {
    0 => 'No calendar yet. Connect one from the calendar any time.',
    1 => '1 calendar bringing your plans in',
    _ => '$count calendars bringing your plans in',
  };
  static const readyOpen = 'Open my week';
}
