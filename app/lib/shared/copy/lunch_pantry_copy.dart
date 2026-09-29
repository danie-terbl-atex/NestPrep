/// Every word the pantry says (lunch-box ADR-0006), `FE-19`.
abstract final class LunchPantryCopy {
  static const title = 'Pantry';
  static const subtitle = 'What is in the house for lunches';

  // On the board.
  static const planFromPantry = 'Plan from what we have';
  static const planFromPantryOn =
      'Suggestions put what is in the house first, and filling the week '
      'uses it before anything else.';
  static const planFromPantryOff =
      'Turn on to plan the week around what is already in the house.';
  static const fillFromPantry = 'Fill from the pantry';
  static String weekNeeds(int things) => things == 1
      ? 'This week needs 1 thing the pantry does not have.'
      : 'This week needs $things things the pantry does not have.';
  static const weekCovered = 'The pantry covers every box this week.';
  static const seeWhatIsMissing = 'See what is missing';

  // Packing today's box.
  static const packedQuestion = 'Today’s box packed?';
  static const markPacked = 'Mark packed';
  static const markPackedHint =
      'Takes one of each thing in it out of the pantry.';
  static const packedDone = 'Packed — taken out of the pantry';
  static const undoPacked = 'Undo';

  // The screen.
  static const addToPantry = 'Add to the pantry';
  static const emptyTitle = 'Nothing in the pantry yet';
  static const emptyBody =
      'Add what is in the house — a bag of apples, the bread — as boxes’ '
      'worth, and plan the week from it.';
  static const inTheHouse = 'In the house';
  static const usedUp = 'Used up';
  static const missingTitle = 'This week still needs';
  static const nothingMissing =
      'Nothing — the pantry covers every box planned from today.';
  static String addMissingToGroceries(int count) =>
      count == 1 ? 'Add it to the grocery list' : 'Add all $count to groceries';
  static String addedToGroceries(int count) => switch (count) {
    0 => 'Everything missing is already on the grocery list.',
    1 => 'Added 1 thing to the grocery list.',
    _ => 'Added $count things to the grocery list.',
  };
  static const groceriesNotShared =
      'You cannot add to the grocery list — ask a parent to share it with '
      'you.';

  /// The quantity a grocery line from the pantry carries.
  static String forBoxes(int boxes) =>
      boxes == 1 ? 'for 1 lunch box' : 'for $boxes lunch boxes';

  // One entry.
  static String enoughFor(int boxes) => switch (boxes) {
    0 => 'None left',
    1 => 'Enough for 1 box',
    _ => 'Enough for $boxes boxes',
  };
  static String weekTakes(int boxes) =>
      boxes == 1 ? 'this week needs 1' : 'this week needs $boxes';
  static String short(int boxes) => 'short by $boxes';
  static String needsBoxes(int boxes) =>
      boxes == 1 ? '1 box’s worth' : '$boxes boxes’ worth';
  static String oneLess(String name) => 'One less $name';
  static String oneMore(String name) => 'One more $name';
  static const topUp = 'Top up';
  static const markUsedUp = 'Mark used up';
  static const remove = 'Take out of the pantry';
  static String entryMenuTitle(String name) => name;

  // Quick add.
  static const addTitle = 'Add to the pantry';
  static const search = 'Find it in the library';
  static const searchHint = 'Apples, bread, biltong…';
  static const aPack = 'Adds 5 boxes’ worth';
  static const alreadyIn = 'In the pantry';
  static const somethingNew = 'Something new';
  static const noMatch = 'Nothing in the library by that name.';

  // In the picker.
  static String inPantry(int boxes) => boxes == 1
      ? 'In the pantry · enough for 1'
      : 'In the pantry · enough for $boxes';
  static const notInPantry = 'Not in the pantry';
}
