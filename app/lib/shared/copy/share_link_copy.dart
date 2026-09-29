import '../failure/app_failure.dart';

/// The words of sharing one document by an expiring link (documents
/// ADR-0006). Its own file beside `AppCopy`, reached through it (`FE-19`);
/// `feature_copy_is_used_test.dart` fails on a word nothing says.
abstract final class ShareLinkCopy {
  // ---- the way in, from a document ----
  static const shareAction = 'Share a link';
  static const sheetTitle = 'Share with a link';
  static const sheetBody =
      'Anyone with the link can open this one document until it ends. They do '
      'not need NestPrep.';

  // ---- how long ----
  static const lifetimeLabel = 'How long it works';
  static String hours(int hours) => switch (hours) {
    1 => '1 hour',
    24 => '1 day',
    72 => '3 days',
    168 => '7 days',
    _ when hours % 24 == 0 => '${hours ~/ 24} days',
    _ => '$hours hours',
  };
  static String untilShiftEnds(String carer) => 'Until $carer\'s shift ends';
  static const shiftNote =
      'It stops the moment the shift ends — and after seven days at the '
      'latest.';

  // ---- the PIN ----
  static const pinToggle = 'Ask for a PIN';
  static const pinToggleNote =
      'Send the PIN separately. Five wrong tries lock the link.';
  static const pinLabel = 'PIN — 4 to 8 numbers';
  static const pinHint = '2468';
  static const pinInvalid = 'Use 4 to 8 numbers.';

  // ---- identity documents ----
  static const identityTitle = 'This looks like an ID document';
  static const identityBody =
      'An ID or passport copy is what fraud starts with. Share it only with '
      'someone you trust, for as short a time as you can — and add a PIN.';
  static const identityConfirm = 'Share it anyway';

  // ---- making it ----
  static const create = 'Make the link';
  static const creating = 'Making the link';
  static const readyTitle = 'Your link is ready';
  static const readyBody =
      'This is the only time NestPrep shows it. Send it now — you can stop it '
      'from Shared links at any time.';
  static const send = 'Send the link';
  static const copy = 'Copy';
  static const copied = 'Link copied';
  static const done = 'Done';
  static String endsAt(String when) => 'Works until $when';
  static const endsWithShift = 'Works until the shift ends';
  static String shareSubject(String document) =>
      'Shared from NestPrep: $document';
  static String shareText(String document, String url) =>
      'Here is $document, shared from NestPrep. The link stops working when it '
      'ends: $url';
  static const withPinReminder = 'Remember to send the PIN separately.';

  // ---- the list ----
  static const listTitle = 'Shared links';
  static const listEntry = 'Shared links';
  static const listEntryBody = 'Every live link, and a way to stop each one.';
  static const listBody =
      'Links that still work. Stopping one takes effect at once.';
  static const emptyTitle = 'Nothing is shared';
  static const emptyBody =
      'Open a document and choose "Share a link" to send it to someone for a '
      'while — a medical aid card for the nanny\'s shift, say.';
  static const withPin = 'PIN';
  static const fromVault = 'From a vault';
  static String opened(int count) => switch (count) {
    0 => 'Not opened yet',
    1 => 'Opened once',
    _ => 'Opened $count times',
  };
  static String lastOpened(String when) => 'last $when';
  static String madeBy(String name) => 'Shared by $name';
  static const stop = 'Stop sharing';
  static const stopTitle = 'Stop this link?';
  static const stopBody =
      'Whoever has it will see that it no longer works. This cannot be undone.';
  static String stopLabel(String document) => 'Stop sharing $document';

  static String problem(DocumentProblem problem) => switch (problem) {
    DocumentProblem.featureOff => 'Sharing links is switched off for now.',
    DocumentProblem.notAllowedToShare =>
      'Only a parent, or the owner of a vault, can share this.',
    DocumentProblem.shiftNotOpen =>
      'That shift has already ended. Choose how long instead.',
    DocumentProblem.tooManyShares =>
      'Too many links are live. Stop one you no longer need first.',
    DocumentProblem.shareNotFound => 'That link is no longer there.',
    _ => 'That link was not made. Please try again.',
  };
}
