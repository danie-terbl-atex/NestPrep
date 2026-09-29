import '../../features/notifications/data/notification_directory.dart';
import '../../features/notifications/model/notification_vocabulary.dart';

/// Every user-facing string of notifications (notifications ADR-0001 to
/// ADR-0003), beside `AppCopy` rather than inside it (`FE-19`). Warm and
/// short: this is the feature that speaks first thing in the morning.
abstract final class NotificationsCopy {
  // ---- the bell and the inbox ----
  static const inboxTitle = 'Notifications';
  static String bellLabel(int unread) =>
      unread == 0 ? inboxTitle : '$inboxTitle, $unread unread';
  static const settingsLabel = 'Notification settings';
  static const markAllRead = 'Mark all read';
  static const today = 'Today';
  static const earlier = 'Earlier';
  static const unread = 'Unread';
  static const clear = 'Clear';
  static const emptyTitle = 'Nothing yet';
  static const emptyMessage =
      'Your morning digest and reminders land here — one calm summary a day, '
      'and a nudge only when something needs you.';
  static const openItem = 'Open';

  static String categoryName(NotificationCategory category) =>
      switch (category) {
        NotificationCategory.digest => 'Morning digest',
        NotificationCategory.documents => 'Document reminder',
        NotificationCategory.handover => 'Shift handover',
        NotificationCategory.chores => 'Chores and rewards',
        NotificationCategory.test => 'Test',
      };

  // ---- turning notifications on (ADR-0003: never at launch) ----
  static const turnOnTitle = 'Hear about your day';
  static const turnOnMessage =
      'One summary each morning — events, lunch boxes, chores — and a nudge '
      'when a document needs renewing or a shift ends. Nothing at night.';
  static const turnOn = 'Turn on notifications';
  static const deniedMessage =
      'Notifications are off for NestPrep in your phone’s settings. Turn them '
      'on there to hear from us.';
  static const unreachableMessage =
      'This phone can’t receive notifications yet. Your inbox still has '
      'everything.';
  static const onMessage = 'Notifications are on for this phone.';

  // ---- a digest, opened ----
  static const digestGone = 'This notification has been cleared.';
  static String sectionTitle(DigestSectionKind? kind) => switch (kind) {
    DigestSectionKind.events => 'On today',
    DigestSectionKind.pack => 'What to pack',
    DigestSectionKind.chores => 'Chores',
    DigestSectionKind.documents => 'Documents to renew',
    DigestSectionKind.shift => 'The nanny hub',
    DigestSectionKind.approvals => 'Waiting for you',
    null => 'More',
  };
  static String sectionLink(DigestSectionKind kind) => switch (kind) {
    DigestSectionKind.events => 'Open the week',
    DigestSectionKind.pack => 'Open lunch',
    DigestSectionKind.chores => 'Open to-dos',
    DigestSectionKind.documents => 'Open documents',
    DigestSectionKind.shift => 'Open the hub',
    DigestSectionKind.approvals => 'Open stars',
  };

  // ---- the settings screen ----
  static const settingsTitle = 'Notification settings';
  static const phoneTitle = 'This phone';
  static const sendTest = 'Send me a test';
  static String testOutcome(TestPushOutcome outcome) => switch (outcome) {
    TestPushOutcome.sent => 'Sent — it should arrive in a moment.',
    TestPushOutcome.noDevice =>
      'This phone isn’t registered yet. Turn notifications on first.',
    TestPushOutcome.failed => 'It didn’t go through. Try again in a minute.',
    TestPushOutcome.alreadySent => 'One is on its way — give it a minute.',
  };

  static const digestTitle = 'Morning digest';
  static const digestSwitch = 'Send me a morning digest';
  static const digestTime = 'Arrives at';
  static String digestNote(String timeZone) =>
      'In the household’s time, $timeZone. On a day with nothing on, we stay '
      'quiet.';
  static const digestHoldsTitle = 'What yours holds';
  static const digestHoldsNothing =
      'Nothing yet — what you can see in this household decides it.';
  static String coverageName(DigestSectionKind kind) => switch (kind) {
    DigestSectionKind.events => 'Today’s events',
    DigestSectionKind.pack => 'Lunch boxes and kit to pack',
    DigestSectionKind.chores => 'Chores due today',
    DigestSectionKind.documents => 'Documents about to expire',
    DigestSectionKind.shift => 'Who is on shift',
    DigestSectionKind.approvals => 'What waits for your check',
  };

  static const remindersTitle = 'Reminders';
  static String categorySwitch(SwitchableCategory category) =>
      switch (category) {
        SwitchableCategory.documents => 'Documents to renew',
        SwitchableCategory.handover => 'Shift handovers',
        SwitchableCategory.chores => 'Chores and rewards',
      };
  static String categoryHint(SwitchableCategory category) => switch (category) {
    SwitchableCategory.documents =>
      'When a passport or a policy is close to expiring',
    SwitchableCategory.handover => 'When a carer ends a shift',
    SwitchableCategory.chores =>
      'When a chore waits for your check, or a reward is asked for',
  };

  static const quietTitle = 'Quiet hours';
  static const quietSwitch = 'Hold notifications overnight';
  static const quietFrom = 'From';
  static const quietUntil = 'Until';
  static const quietNote =
      'Anything that comes in waits in your notifications and buzzes when '
      'quiet hours end.';

  static const kidsTitle = 'Children';
  static const kidsNote =
      'A child’s tablet only ever hears about their own lunch and chores.';
  static const kidDigest = 'Morning digest on their tablet';

  // ---- the kid's tablet ----
  static const kidTurnOn = 'Turn on reminders';
  static const kidOn = 'Reminders are on';

  // ---- Android channels, as the phone's own settings name them ----
  static String channelName(AndroidChannel channel) => switch (channel) {
    AndroidChannel.digest => 'Morning digest',
    AndroidChannel.documents => 'Document reminders',
    AndroidChannel.handover => 'Shift handovers',
    AndroidChannel.chores => 'Chores and rewards',
  };
  static String channelDescription(AndroidChannel channel) => switch (channel) {
    AndroidChannel.digest => 'One summary of your day, each morning',
    AndroidChannel.documents => 'When a household document needs renewing',
    AndroidChannel.handover => 'When a carer ends a shift',
    AndroidChannel.chores => 'Chores to check and rewards asked for',
  };
}
