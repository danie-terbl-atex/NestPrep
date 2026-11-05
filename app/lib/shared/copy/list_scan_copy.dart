import '../../features/groceries/model/product_match.dart';
import '../failure/app_failure.dart';
import 'checkers_copy.dart';

/// Every word snap-a-shopping-list says (`FE-19`, list-scan ADR-0001). The
/// tone is somebody reading the fridge list out while you type.
abstract final class ListScanCopy {
  static const title = 'Snap a list';
  static const open = 'Snap a shopping list';

  // Choosing a photo.
  static const heroTitle = 'Turn any list into your grocery list';
  static const heroBody =
      'Take a photo of a handwritten list, the whiteboard or a message. '
      'Every item comes back for you to check before anything is added.';
  static const takePhoto = 'Take a photo';
  static const choosePhoto = 'Choose a photo';
  static const privacyTitle = 'What leaves your phone';
  static const privacyBody =
      'Only the photo, read by Google’s Gemini in Europe and not kept. '
      'Nothing about your family goes with it.';
  static const tryAgain = 'Try again';

  // Reading.
  static const readingTitle = 'Reading your list…';
  static const readingBody =
      'Picking out every item. This takes a few seconds.';

  // Reviewing.
  static String found(int count) => switch (count) {
    1 => 'We read 1 item',
    _ => 'We read $count items',
  };
  static const reviewBody =
      'Untick anything you don’t need. Tap the pencil to fix a name or how '
      'much.';
  static const noneTitle = 'No list in that photo';
  static const noneBody =
      'Nothing to buy came through. A closer, brighter photo usually does it.';
  static const tryAnother = 'Try another photo';
  static String change(String name) => 'Change $name';
  static String ticked(String name) => '$name, will be added';
  static String unticked(String name) => '$name, left off';
  static String addToList(int count) => switch (count) {
    0 => 'Tick an item to add it',
    1 => 'Add 1 to the list',
    _ => 'Add $count to the list',
  };
  static String findAt(ProductRetailer shop) =>
      'Find at ${CheckersCopy.retailerName(shop)}';
  static const findAtYourShop = 'Find at my shop';
  static const startOver = 'Start over';

  // Changing a line.
  static const editTitle = 'Change item';
  static const nameLabel = 'Item';
  static const save = 'Save';
  static const remove = 'Leave it off';

  // Done.
  static String addedTitle(int count) => switch (count) {
    0 => 'It’s all on your list already',
    1 => '1 item is on your list',
    _ => '$count items are on your list',
  };
  static const addedBody = 'Everyone in the household sees them now.';
  static const backToList = 'Back to the list';
  static const snapAnother = 'Snap another list';

  static String problem(ListScanProblem problem) => switch (problem) {
    ListScanProblem.listScanOff =>
      'Reading shopping lists is switched off for now.',
    ListScanProblem.groceriesNotShared =>
      'You can see this grocery list, and adding to it is up to a parent.',
    ListScanProblem.listPhotoTooLarge =>
      'That photo is too big to read. Try taking it again.',
    ListScanProblem.listPhotoNotSupported =>
      'That isn’t a photo NestPrep can read.',
    ListScanProblem.pickerUnavailable =>
      'The camera or your photos would not open. Check NestPrep may use them.',
  };
}
