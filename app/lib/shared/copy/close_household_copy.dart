/// Every user-facing string of closing a household (household ADR-0007),
/// beside `AppCopy` so the feature's words are one file's reading (`FE-19`).
///
/// Like deleting an account, this is where the app is deliberately slow to
/// say yes: plain words about what goes, never a joke, never a guilt trip.
abstract final class CloseHouseholdCopy {
  // ---- on the household screen ----
  static const entry = 'Close household';
  static const entryHint =
      'You are the only grown-up here, so you can close the household for '
      'good. To keep it going, invite another parent and make them an admin.';

  // ---- the close screen ----
  static const title = 'Close household';
  static String lead(String household) =>
      'Closing $household deletes it for good, with everything in it. Nobody '
      'can open it again, and it cannot be undone.';
  static const goesTitle = 'What is deleted';
  static const goes = [
    'Everyone’s profiles, and the children’s details and medication',
    'The calendar, lists, meal and lunch plans, chores and routines',
    'Documents, vaults and photos, with every file in them',
    'Invite codes, and every kid sign-in on a child’s device',
  ];
  static const staysTitle = 'What stays';
  static const stays = [
    'Your account — you can start or join another household',
    'A link with a child’s other home ends; that home keeps what it was '
        'already shown',
  ];
  static String othersLoseAccess(int others) =>
      '${others == 1 ? 'One other person loses' : '$others other people lose'} '
      'access straight away.';
  static const premiumNote =
      'A premium subscription paid through the App Store or Google Play keeps '
      'billing until you cancel it there. Closing does not cancel it.';
  static const downloadFirst = 'Download my data first';
  static const deleteAccountInstead =
      'Want your account gone too? Delete my account closes this household '
      'as part of it.';
  static const deleteAccountButton = 'Delete my account instead';
  static const confirmLabel = 'Type CLOSE to confirm';
  static const confirmHint = 'CLOSE';
  static const closeButton = 'Close household for good';
  static const closing = 'Closing…';
}
