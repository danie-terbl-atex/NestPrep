/// Every word *Fill the week* says (`FE-19`, lunch-box ADR-0020): choose
/// boxes, see the whole week, then fill it.
abstract final class FillWeekCopy {
  static const title = 'Fill the week';
  static String forChild(String name, String week) => 'For $name · $week';

  static const stepNames = ['Boxes', 'Review', 'Done'];
  static String stepOf(int number) =>
      'Step $number of ${stepNames.length}: ${stepNames[number - 1]}';
  static const back = 'Back';

  static const noChildTitle = 'We can’t find this child';
  static const noChildBody =
      'They may no longer be marked as a child. Go back to the lunch board '
      'and choose again.';

  // ---- 1. boxes ----
  static String boxesHeadline(String name) => 'Pick boxes for $name’s week';
  static const boxesBody =
      'Choose any you like — they take turns through the week. NestPrep '
      'fills everything else from what they eat. Nothing is saved yet.';
  static const goToHeader = 'Your go-to boxes';
  static String noGoToBoxes(String name) =>
      'No go-to boxes for $name yet. Save one from any day’s menu on the '
      'lunch board.';
  static const readyMadeHeader = 'Ready-made by NestPrep';
  static const noReadyMade = 'No ready-made boxes right now.';
  static const nothingToChooseTitle = 'No boxes to choose from yet';
  static const nothingToChooseBody =
      'NestPrep can still fill the whole week from what they eat.';
  static const recipe = 'Recipe';
  static const recipeOpen = 'Recipe · tap for how to make it';
  static const quickPick = 'Quick pick';
  static const fridayOnly = 'Fridays only';
  static String willFillInstead(String things) =>
      'We’ll fill this instead (contains $things)';
  static const nuts = 'nuts';
  static String notSafeAnyMore(String name) =>
      'Not safe for $name any more — swap what’s flagged on the board first.';
  static const choose = 'Choose';
  static String chosenTurn(int turn) => 'Chosen · box $turn';
  static String chooseBox(String box) => 'Choose $box';
  static String unchooseBox(String box) => 'Leave out $box';

  static const reviewAction = 'Review the week';
  static const skipAction = 'Skip — fill it all for me';

  // ---- 2. review ----
  static String reviewHeadline(String name) => 'Here’s $name’s week';
  static const reviewBody =
      'Each new lunch says where it came from. Nothing is saved until you '
      'fill the week.';
  static String fromBox(String box) => 'From $box';
  static const byNestPrep = 'NestPrep’s pick';
  static const alreadyPacked = 'Already packed';
  static const dayGone = 'Gone — left as it is';
  static const dayUnchanged = 'Nothing to add';
  static const nothingToFillTitle = 'Nothing left to fill';
  static const nothingToFillBody =
      'Every open school day is packed already, or the library has nothing '
      'safe for the empty compartments. Add items to the library to fill more.';
  static const noDaysLeftTitle = 'This week’s school days have gone';
  static const noDaysLeftBody =
      'Move the lunch board to next week to fill that one.';
  static const fillAction = 'Fill the week';

  // ---- 3. done ----
  static String doneHeadline(String name) => '$name’s week is filled';
  static String packed(int lunches) =>
      '${lunches == 1 ? '1 compartment' : '$lunches compartments'} packed. '
      'You’ll see them on the lunch board.';
  static const packedNothing = 'Nothing went in.';
  static String skipped(int count) =>
      '${count == 1 ? '1 couldn’t' : '$count couldn’t'} go in — packed '
      'meanwhile, no longer safe, or not allowed for this child.';
  static const doneAction = 'Back to the lunch board';
}
