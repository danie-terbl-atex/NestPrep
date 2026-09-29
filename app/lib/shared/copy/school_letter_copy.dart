import '../failure/app_failure.dart';

/// Every word snap-a-school-letter says (`FE-19`, calendar ADR-0005), in a
/// file of its own reached through `app_copy.dart`. The tone is a friend
/// taking the fridge letter off the parent's hands.
abstract final class SchoolLetterCopy {
  static const title = 'Snap a school letter';
  static const openFromWeek = 'Snap a school letter';

  // Choosing a letter.
  static const heroTitle = 'Turn a school letter into events';
  static const heroBody =
      'Take a photo of the newsletter, or choose a photo or the PDF the '
      'school sent. You check every event before anything is added.';
  static const takePhoto = 'Take a photo';
  static const choosePhoto = 'Choose a photo';
  static const choosePdf = 'Choose a PDF';
  static const pdfPickerLabel = 'PDF letters';
  static const privacyTitle = 'What leaves your phone';
  static const privacyBody =
      'The letter is read by Google’s Gemini in Europe and is not kept. To '
      'match events to your children we share only their school and grade — '
      'never their names.';
  static const tryAgain = 'Try again';
  static const chooseAnother = 'Choose another letter';

  // Reading.
  static const readingTitle = 'Reading the letter…';
  static const readingBody = 'Finding the dates. This takes a few seconds.';

  // Reviewing.
  static String found(int count) => switch (count) {
    1 => 'We found 1 event',
    _ => 'We found $count events',
  };
  static const reviewBody =
      'Untick anything you do not need. Tap an event to change it.';
  static const noneTitle = 'No dates in that letter';
  static const noneBody =
      'Nothing with a date came through. A sharper photo, or the next page, '
      'might have them.';
  static String addTicked(int count) => switch (count) {
    0 => 'Tick an event to add it',
    1 => 'Add 1 event',
    _ => 'Add $count events',
  };
  static const edit = 'Change';
  static String ticked(String title) => '$title, will be added';
  static String unticked(String title) => '$title, will not be added';

  // Done.
  static String addedTitle(int count) => switch (count) {
    1 => '1 event is on the calendar',
    _ => '$count events are on the calendar',
  };
  static const addedBody =
      'Everyone in the household sees them on the week now.';
  static const seeTheWeek = 'See the week';
  static const snapAnother = 'Snap another letter';

  static String problem(SchoolLetterProblem problem) => switch (problem) {
    SchoolLetterProblem.letterFeatureOff =>
      'Reading school letters is switched off for now.',
    SchoolLetterProblem.letterTooLarge =>
      'That file is too big to read. Try a photo, or a shorter PDF.',
    SchoolLetterProblem.letterNotSupported =>
      'That is not a photo or a PDF NestPrep can read.',
    SchoolLetterProblem.pickerUnavailable =>
      'The camera or your files would not open. Check NestPrep may use them.',
    SchoolLetterProblem.someNotAdded =>
      'Some events could not be added. They are still ticked — try again.',
  };
}
