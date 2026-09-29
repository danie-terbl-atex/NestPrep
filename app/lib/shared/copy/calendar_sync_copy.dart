import '../../features/calendar_sync/model/calendar_provider.dart';
import '../../features/calendar_sync/model/connection_status.dart';
import '../failure/app_failure.dart';

/// Every word the connected calendars say (`FE-19`, calendar ADR-0003) — kept
/// beside `AppCopy` rather than inside it, because it is one feature's
/// vocabulary and the shared file is edited by every feature at once.
/// `AppCopy.failure` reaches [problem] through one line.
abstract final class CalendarSyncCopy {
  static const title = 'Connected calendars';
  static const subtitle = 'Everyone’s calendars, in the family week';
  static const openFromWeek = 'Connected calendars';

  static const sectionConnect = 'Bring a calendar in';
  static const sectionConnected = 'Connected';
  static const sectionShare = 'The family week, in your own calendar';

  static const connect = 'Connect';
  static const notSetUp = 'Not set up yet';
  static const privacyNote =
      'Everyone in the household sees the titles and times of the events you '
      'bring in. Nothing is ever changed in your own calendar.';
  static const browserOpened =
      'Finish connecting in your browser, then come back here. The calendar '
      'appears below as soon as it is connected.';

  static const emptyTitle = 'Nothing connected yet';
  static const emptyBody =
      'Connect a calendar above and its events join the family week.';

  static const linkSheetTitle = 'Add a calendar link';
  static const linkLabel = 'Calendar link';
  static const linkHint = 'webcal://';
  static const linkHelp =
      'In Apple Calendar, open the calendar’s settings, turn on Public '
      'Calendar and copy the link. A school or club calendar link works too.';
  static const linkAdd = 'Add calendar';

  static const syncNow = 'Sync now';
  static const disconnect = 'Disconnect';
  static const disconnectConfirm = 'Disconnect this calendar?';
  static const disconnectBody =
      'Its events leave the family week. Nothing changes in the calendar '
      'itself.';

  static const feedBlurb =
      'Subscribe from Apple, Google or Outlook and the household’s own '
      'events appear there, kept up to date.';
  static const feedGetLink = 'Get the link';
  static const feedCopy = 'Copy link';
  static const feedCopied = 'Link copied';
  static const feedSubscribe = 'Subscribe on this phone';
  static const feedReset = 'Make a new link';
  static const feedResetConfirm = 'Make a new link?';
  static const feedResetBody =
      'The old link stops working for everyone who subscribed with it. They '
      'will need the new one.';
  static const feedPrivacy =
      'Anyone with this link can see the titles and times of the family '
      'week. Share it only with the household.';

  static const syncedBusy = 'Busy';

  /// Whose calendar it was, once their profile has left the household.
  static const formerMember = 'Somebody';
  static const syncedReadOnlyBody =
      'It is changed in the calendar it comes from, and the week catches up '
      'within half an hour.';

  static String providerName(CalendarProvider provider) => switch (provider) {
    CalendarProvider.google => 'Google Calendar',
    CalendarProvider.microsoft => 'Outlook',
    CalendarProvider.ics => 'Apple or a calendar link',
  };

  static String providerBlurb(CalendarProvider provider) => switch (provider) {
    CalendarProvider.google => 'Your Google account’s main calendar.',
    CalendarProvider.microsoft => 'Work, school or Outlook.com.',
    CalendarProvider.ics =>
      'A shared iCloud calendar, or a school or club calendar link.',
  };

  /// The short name on an imported event's badge. A link to iCloud is Apple's,
  /// and says so.
  static String sourceName(CalendarProvider provider, {String label = ''}) =>
      switch (provider) {
        CalendarProvider.google => 'Google',
        CalendarProvider.microsoft => 'Outlook',
        CalendarProvider.ics => label.contains('icloud.com') ? 'Apple' : 'Link',
      };

  /// "Sam's Google Calendar", "Thandi's Apple calendar".
  static String connectionTitle(
    String ownerName,
    CalendarProvider provider, {
    String label = '',
  }) => switch (provider) {
    CalendarProvider.google => '$ownerName’s Google Calendar',
    CalendarProvider.microsoft => '$ownerName’s Outlook calendar',
    CalendarProvider.ics =>
      label.contains('icloud.com')
          ? '$ownerName’s Apple calendar'
          : '$ownerName’s calendar link',
  };

  static String syncedFrom(String connectionTitle) => 'From $connectionTitle';

  static String eventCount(int count) =>
      count == 1 ? '1 event' : '$count events';

  /// The line under a connection: how it is, in words.
  static String status(
    ConnectionStatus status, {
    required String? syncedAgo,
    required int eventCount,
  }) => switch (status) {
    ConnectionStatus.connected =>
      syncedAgo == null
          ? 'Waiting for its first sync'
          : 'Synced ${syncedAgo.toLowerCase()} · '
                '${CalendarSyncCopy.eventCount(eventCount)}',
    ConnectionStatus.revoked =>
      'NestPrep can no longer read this calendar. Disconnect it and connect '
          'it again.',
    ConnectionStatus.unreachable =>
      'Could not be reached at the last try. NestPrep keeps trying.',
    ConnectionStatus.notACalendar => 'This link no longer leads to a calendar.',
    ConnectionStatus.notConfigured =>
      'This kind of calendar is not set up on NestPrep yet.',
  };

  static String problem(CalendarSyncProblem problem) => switch (problem) {
    CalendarSyncProblem.notYourConnection =>
      'Only the person who connected it, or an admin, can do that.',
    CalendarSyncProblem.connectionNotFound =>
      'That calendar is no longer connected.',
    CalendarSyncProblem.providerNotConfigured =>
      'That kind of calendar is not set up on NestPrep yet.',
    CalendarSyncProblem.notACalendarLink =>
      'That link is not a calendar NestPrep can read. Check it is the public '
          'calendar link.',
    CalendarSyncProblem.calendarLinkUnreachable =>
      'That calendar could not be reached just now. Try again in a moment.',
    CalendarSyncProblem.couldNotOpenBrowser =>
      'Nothing on this phone would open the sign-in page.',
  };
}
