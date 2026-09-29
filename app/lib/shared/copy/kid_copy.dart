import '../failure/app_failure.dart';

/// Every user-facing string of kid sign-in (accounts ADR-0003), beside
/// `AppCopy` rather than inside it so the copy file stays one screen's worth
/// of reading per feature (`FE-19`). `AppCopy.failure` reads [problem], so a
/// kid failure is still turned into words in one place.
///
/// Two voices live here. The parent's is the app's usual one. The kid's is
/// shorter, warmer and never blames: a seven-year-old who typed a letter wrong
/// is told to try again, not that a credential was invalid.
abstract final class KidCopy {
  // ---- the way in, on the sign-in screen ----
  static const signInPrompt = 'Are you a kid?';
  static const signInWithCode = 'I have a code from a grown-up';

  // ---- the code screen, read by a child ----
  static const codeTitle = 'Hello there!';
  static const codeBody =
      'Ask a grown-up to open NestPrep, go to Household, and make you a code. '
      'Then type it here.';
  static const codeFieldLabel = 'Your six-letter code';
  static const codeSubmit = 'Let me in';
  static const codeBackToSignIn = 'I am a grown-up';

  // ---- the kid's home ----
  static String greeting(String name) => 'Hi, $name!';
  static const homeTitle = 'My day';
  static const choresTitle = 'My jobs today';
  static const choresNone = 'No jobs today';
  static const choresNoneBody = 'Nothing to do but enjoy it.';
  static const choresAllDone = 'All done!';
  static const choresAllDoneBody = 'Every job ticked off. Brilliant work.';
  static const choreOverdue = 'From before';
  static const choreTapToFinish = 'Tap when it is done';
  static const choreDone = 'Done!';
  static const choreToDo = 'Still to do';
  static const nothingShownTitle = 'Nothing here yet';
  static const nothingShownBody =
      'A grown-up chooses what shows on this device. Ask them to open '
      'Household on their phone.';
  static const foodTitle = 'Today’s food';
  static const foodNothingPlanned = 'Not planned yet';
  static const signOut = 'Sign this device out';
  static const signOutConfirm = 'Sign out of NestPrep?';
  static const signOutBody =
      'You will need a new code from a grown-up to come back in.';
  static const signOutCancel = 'Stay signed in';
  static const disconnectedTitle = 'This device is signed out';
  static const disconnectedAction = 'Back to the start';

  static String choresProgress(int done, int total) => '$done of $total done';

  // ---- the parent's screen ----
  static const manageTitle = 'Kids’ sign-in';
  static const manageEntry = 'Kids’ sign-in';
  static const manageEntryBody =
      'Let a child sign in on their own tablet with a code — no email needed.';
  static const manageIntro =
      'A child signs in with a code you make here. Their device shows what you '
      'chose for them under Household — to begin with, their own jobs and '
      'today’s food.';
  static const manageEmptyTitle = 'No children to sign in yet';
  static const manageEmptyBody =
      'Add a person with the Kid role who has not joined. They can then sign '
      'in here on their own device.';
  static const manageAddDevice = 'Add a device';
  static const manageSignOutEverywhere = 'Sign out everywhere';
  static const manageSignOutEverywhereConfirm = 'Sign out every device?';
  static const manageRevoke = 'Sign out';
  static const manageRevokeConfirm = 'Sign this device out?';
  static const manageCancel = 'Cancel';
  static const manageUnnamedDevice = 'A device';
  static const manageNoDevices = 'Not signed in anywhere';

  static String manageDeviceCount(int count) => switch (count) {
    1 => 'Signed in on 1 device',
    _ => 'Signed in on $count devices',
  };

  static String managePairedOn(String date) => 'Paired $date';
  static const manageGoToHousehold = 'Go to Household';

  // ---- the pairing sheet ----
  static const pairTitle = 'Add a device';
  static const pairLabel = 'What is the device called?';
  static const pairLabelHint = 'Tablet, phone… (optional)';
  static const pairMakeCode = 'Make a code';
  static const pairBody =
      'On the child’s device, open NestPrep, tap “I have a code from a '
      'grown-up”, and type this.';
  static const pairWaiting = 'Waiting for the device…';
  static const pairExpired = 'That code has run out.';
  static const pairMakeAnother = 'Make a new code';
  static const pairDone = 'Done';

  static String pairTimeLeft(int minutes, int seconds) =>
      '${minutes.toString()}:${seconds.toString().padLeft(2, '0')} left';

  static String pairSucceeded(String name) => '$name is signed in!';

  static String problem(KidSignInProblem problem) => switch (problem) {
    KidSignInProblem.notEligible =>
      'Only a child’s profile that nobody has joined as can have a kid '
          'sign-in.',
    KidSignInProblem.tooManyDevices =>
      'That child is already signed in on five devices. Sign one out first.',
    KidSignInProblem.codeNotFound =>
      'That code did not work. Check each letter and try again.',
    KidSignInProblem.codeExpired =>
      'That code has run out. Ask your grown-up for a new one.',
    KidSignInProblem.deviceNotFound => 'That device is already signed out.',
    KidSignInProblem.signInUnavailable =>
      'Kid sign-in is not working right now. A grown-up can try again later.',
    KidSignInProblem.tooManyAttempts =>
      'That was a lot of tries. Wait ten minutes, then ask your grown-up for '
          'a new code.',
    KidSignInProblem.deviceDisconnected =>
      'A grown-up has signed this device out. Ask them for a new code.',
  };
}
