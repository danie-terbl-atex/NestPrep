/// The words for making and accepting a link between two homes, and for the
/// privacy boundary shown at both (household ADR-0004). Split from
/// `two_homes_copy.dart` to keep each file one job (`ENG-05`).
abstract final class TwoHomesSetupCopy {
  // Making a code.
  static const setupTitle = 'Link with another home';
  static const whichChild = 'Which child?';
  static const noKidsTitle = 'Add your child first';
  static const noKidsBody =
      'Add them on the household screen as a kid, then come back to link '
      'homes.';
  static const yourHome = 'Your home';
  static const homeNameLabel = 'What to call your home';
  static const homeNameHint = 'Mum’s home';
  static const homeColour = 'Its colour on the calendar';
  static const theOtherHome = 'The other home';
  static const scheduleTitle = 'The schedule';
  static const scheduleBody =
      'Propose one now; the other home sees it before they accept, and either '
      'home can suggest a change later.';
  static const makeCode = 'Make a code';
  static const codeTitle = 'A code for the other home';
  static const codeBody =
      'Share it with the other home’s admin. It works once, for seven days. '
      'Nothing is shared until they accept and you confirm.';
  static const shareCode = 'Share the code';
  static const copyCode = 'Copy code';
  static const codeCopied = 'Copied';
  static const done = 'Done';
  static String shareSubject(String child) => 'Linking our homes for $child';
  static String shareMessage({
    required String child,
    required String code,
    Uri? appLink,
  }) =>
      'I’d like to share $child’s schedule and handover notes with you on '
      'NestPrep. In NestPrep, open Household › Two homes › I have a code, '
      'and enter $code. It works for seven days.'
      '${appLink == null ? '' : ' Get the app: $appLink'}';

  // Accepting a code.
  static const joinTitle = 'I have a code';
  static const codeLabel = 'Code from the other home';
  static const checkCode = 'Check the code';
  static String offerTitle(String home, String child) =>
      '$home would like to share $child’s schedule with you';
  static const theirSchedule = 'The schedule they propose';
  static String yourProfileFor(String child) => 'Your profile for $child';
  static String addAsNewKid(String child) => 'Add $child as a new kid';
  static const acceptLink = 'Accept and link';
  static String acceptedTitle(String home) => 'Waiting for $home';
  static const acceptedBody =
      'Once they confirm, the schedule appears on your week and handovers '
      'are shared.';

  // The privacy boundary.
  static const privacyTitle = 'What the other home can see';
  static const privacyOpen = 'What the other home can see';
  static const privacyOpenBody = 'Only this child’s schedule and handovers.';
  static const sharedHeading = 'Shared with the other home';
  static const privateHeading = 'Stays in your home';
  static const sharedItems = [
    'Your child’s first name',
    'Your home’s name and colour',
    'The schedule and any swaps both homes agreed',
    'Handovers: the bag checklist, medicine given, homework, clothes and '
        'notes',
    'Requests to swap days or change the schedule, and the answers',
  ];
  static const privateItems = [
    'Your household’s name, its people and their roles',
    'Your calendar, to-dos, meals, groceries and documents',
    'Allergies, medication and sizes — unless you write them in a handover',
    'Who in your home wrote something: it says your home’s name, never a '
        'person’s',
    'Your other children',
  ];
  static const privacyFooter =
      'Either home can end the link at any time. What was already shared '
      'stays with both homes.';
}
