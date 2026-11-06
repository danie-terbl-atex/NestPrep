import '../../features/todos/model/chore_picture.dart';

/// Every word of a task's picture (todos ADR-0005), beside `AppCopy` rather
/// than inside it (`FE-19`). The picture is for a child who cannot read yet;
/// the words are for the grown-up choosing it.
abstract final class ChorePictureCopy {
  static const fieldLabel = 'Picture';
  static const fieldHelp = 'A picture helps little ones who can’t read yet.';
  static const morePictures = 'More pictures…';
  static const choosePicture = 'Choose a picture';
  static const remove = 'Remove picture';
  static String use(String label) => 'Use picture: $label';
  static String chosen(String label) => 'Picture: $label. Tap to change';

  static const pickerTitle = 'Choose a picture';
  static const searchLabel = 'Search pictures';
  static const searchHint = 'Try teeth, dog or dishes';
  static const suggested = 'Suggested';
  static const all = 'All';
  static const noPicture = 'No picture';
  static const nothingFound = 'No pictures match that. Try another word.';

  static String category(ChorePictureCategory category) => switch (category) {
    ChorePictureCategory.morning => 'Morning',
    ChorePictureCategory.hygiene => 'Washing and teeth',
    ChorePictureCategory.bedroom => 'Bedroom',
    ChorePictureCategory.kitchen => 'Kitchen',
    ChorePictureCategory.meals => 'Mealtimes',
    ChorePictureCategory.laundry => 'Laundry',
    ChorePictureCategory.cleaning => 'Cleaning',
    ChorePictureCategory.outdoor => 'Outside',
    ChorePictureCategory.pets => 'Pets',
    ChorePictureCategory.school => 'School',
    ChorePictureCategory.bedtime => 'Bedtime',
    ChorePictureCategory.helping => 'Helping out',
    ChorePictureCategory.activities => 'Activities',
    ChorePictureCategory.kindness => 'Kindness',
  };
}
