import '../failure/app_failure.dart';

/// Every user-facing string of the account centre, Download my data and
/// Delete my account (accounts ADR-0006), beside `AppCopy` so each feature's
/// words are one file's reading (`FE-19`). `AppCopy.failure` reads [problem].
///
/// Deleting is the one place the app is deliberately slow to say yes: plain
/// words about what goes and what stays, never a joke, never a guilt trip.
abstract final class AccountDataCopy {
  // ---- the account centre ----
  static const centreTitle = 'Account and privacy';
  static const centreSubtitle = 'Your data, your choices';
  static const centreEntry = 'Account and privacy';
  static const yourDataSection = 'Your data';
  static const aboutSection = 'About NestPrep';
  static const downloadRow = 'Download my data';
  static const downloadRowHint = 'Everything NestPrep keeps about you';
  static const deleteRow = 'Delete my account';
  static const deleteRowHint = 'Close your account for good';

  // ---- Download my data ----
  static const exportTitle = 'Download my data';
  static const exportLead =
      'Get a copy of everything NestPrep keeps about you, in one file you can '
      'save or send anywhere.';
  static const exportIncludesTitle = 'What is in it';
  static const exportIncludes = [
    'Your account: your name, email address and how you sign in',
    'Each household you are in, your role and what you may see',
    'Your profile, allergies, medication and last shared location',
    'A list of the files in your vault, and who opened them',
    'The things you added — events, tasks, lists, meals and more',
  ];
  static const exportFilesNote =
      'Vault files are listed, not copied. Open them from your vault any time.';
  static const exportPrepare = 'Prepare my data';
  static const exportPreparing = 'Gathering your data…';
  static const exportReadyTitle = 'Your data is ready';
  static String exportReadyBody(int files) => files == 0
      ? 'One file, ready to save or share.'
      : 'One file, ready to save or share. It lists '
            '$files ${files == 1 ? 'vault file' : 'vault files'}.';
  static const exportShare = 'Save or share';
  static const exportAgain = 'Prepare it again';
  static const exportPrivacyNote =
      'Only you can fetch it, and only for an hour. After that it is deleted.';

  // ---- Delete my account ----
  static const deleteTitle = 'Delete my account';
  static const deleteLead =
      'This closes your NestPrep account for good. Read what will happen '
      'first — it cannot be undone.';
  static const deleteNoHouseholds =
      'You are not in a household, so only your account goes.';
  static const deleteHouseholdsTitle = 'Your households';
  static const deleteGoesTitle = 'What is deleted';
  static const deleteGoes = [
    'Your account and the way you sign in',
    'Your profile details, allergies, medication and shared location',
    'Your vault and every file in it',
    'Calendars you connected',
  ];
  static const deleteStaysTitle = 'What stays with a household that goes on';
  static const deleteStays = [
    'Things you added to shared lists, the calendar and plans',
    'Your name on those things, as the household knows you',
  ];
  static String outcomeLeave(String household) =>
      'You leave $household. Everyone else carries on.';
  static String outcomeHandOver(String household, String successor) =>
      '$successor becomes the admin of $household, and you leave it.';
  static String outcomeEnd(String household, int others) => others == 0
      ? '$household ends, with everything in it.'
      : '$household ends, with everything in it. '
            '${others == 1 ? 'One other person loses' : '$others other people lose'} '
            'access.';
  static const outcomeEndHint =
      'To keep it going, invite another parent and make them an admin first.';
  static const outcomePremiumEnds = 'Its premium ends with it.';
  static String renewingSubscriptions(int count) =>
      'You pay for ${count == 1 ? 'a subscription' : '$count subscriptions'} '
      'through your app store. Deleting your account does not cancel '
      '${count == 1 ? 'it' : 'them'} — cancel in the App Store or Google Play '
      'first.';
  static const deleteConfirmLabel = 'Type DELETE to confirm';
  static const deleteConfirmHint = 'DELETE';
  static const deleteButton = 'Delete my account';
  static const deleteDeleting = 'Deleting…';
  static const deleteKeepInstead = 'Download my data first';

  static String problem(AccountDataProblem problem) => switch (problem) {
    AccountDataProblem.deletionPlanChanged =>
      'Something changed in one of your households. Read it again below, '
          'then confirm.',
    AccountDataProblem.deletionNotConfirmed =>
      'Type DELETE in the box to confirm.',
    AccountDataProblem.tooManyRequests =>
      'You have prepared your data a few times this hour. Try again later.',
    AccountDataProblem.downloadFailed =>
      'Your data was prepared but did not download. Try again.',
    AccountDataProblem.shareUnavailable =>
      'Nothing on this phone offered to save the file. Try again.',
  };
}
