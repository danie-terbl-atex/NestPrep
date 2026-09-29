import '../../features/family_profiles/model/food_rules.dart';
import '../../features/lunch_box/model/lunch_slot.dart';
import '../failure/app_failure.dart';
import 'family_copy.dart';

/// Every word the lunch-box screens say (`FE-19`), in a file of its own
/// exported from `app_copy.dart`, as family profiles does — so the launch
/// feature does not grow the one copy file past reading, and parallel
/// features do not edit the same lines.
abstract final class LunchCopy {
  static const tab = 'Lunch';
  static const title = 'Lunch boxes';

  static String weekOf(String range) => 'School week · $range';
  static const previousWeek = 'Previous week';
  static const nextWeek = 'Next week';
  static const backToThisWeek = 'Back to this week';
  static const thisWeek = 'This week';
  static const nextWeekName = 'Next week';
  static const lastWeek = 'Last week';

  // Who the lunches are for.
  static String packingFor(String name) => 'Packing for $name';
  static String chooseChild(String name) => 'Show $name’s lunches';
  static const noChildrenTitle = 'Who are we packing for?';
  static const noChildrenBody =
      'Mark your children in Family profiles, with their allergies and '
      'school, and their lunch boxes appear here.';
  static const openFamily = 'Open Family profiles';
  static const cannotSeeChildren =
      'Lunches are planned around each child’s allergies, and you have not '
      'been given their profiles. Ask a parent to share Family profiles with '
      'you.';

  // The hero.
  static const todaysBox = 'Today’s box';
  static const tomorrowsBox = 'Tomorrow’s box';
  static String boxFor(String day) => '$day’s box';
  static String packedCount(int filled) =>
      '$filled of ${LunchSlot.values.length} packed';
  static const nothingPackedYet = 'Nothing packed yet';
  static const fillWeek = 'Fill the week';
  static const fillWeekHint =
      'Uses go-to boxes first, then what they eat. Never replaces what you '
      'packed.';
  static String goToBoxCount(int count) => switch (count) {
    0 => 'No go-to boxes yet',
    1 => '1 go-to box in rotation',
    _ => '$count go-to boxes in rotation',
  };
  static String boxArtLabel(String items) =>
      items.isEmpty ? 'An empty lunch box' : 'A lunch box with $items';
  static const weekIsFull = 'Every day is packed.';
  static String filledDays(int days, int fromFavourites) {
    final packed = days == 1 ? 'Packed 1 day' : 'Packed $days days';
    if (fromFavourites == 0) return '$packed from what they eat.';
    return '$packed — $fromFavourites from go-to boxes.';
  }

  static const filledNothing =
      'Nothing to add — every empty slot needs an item the library does not '
      'have yet.';
  static const weekHasUnsafe =
      'Something packed this week is not safe for them any more. It is '
      'marked below — swap it before it goes to school.';

  // Slots.
  static String slotName(LunchSlot slot) => switch (slot) {
    LunchSlot.main => 'Main',
    LunchSlot.fruit => 'Fruit',
    LunchSlot.veg => 'Veg',
    LunchSlot.snack => 'Snack',
    LunchSlot.treat => 'Treat',
  };

  static String addToSlot(LunchSlot slot) => switch (slot) {
    LunchSlot.main => 'Add a main',
    LunchSlot.fruit => 'Add fruit',
    LunchSlot.veg => 'Add veg',
    LunchSlot.snack => 'Add a snack',
    LunchSlot.treat => 'Add a treat',
  };

  // A day.
  static const today = 'Today';
  static const dayActions = 'More for this day';
  static const saveAsFavourite = 'Save as a go-to box';
  static const packFavourite = 'Pack a go-to box';
  static const clearDay = 'Empty this box';
  static const unsafeTag = 'Not safe';
  static String doesNotLike(String what) => 'Does not like $what';

  // Eaten or not.
  static const cameHomeQuestion = 'Did it come home eaten?';
  static const ateIt = 'Ate it';
  static const leftIt = 'Left it';
  static const ateItAll = 'Came home eaten';
  static const cameBackFull = 'Came home full';
  static const markItems = 'Item by item';
  static const changeMark = 'Change';
  static const markItemsTitle = 'What came home eaten?';
  static const saveMarks = 'Save';
  static const undoMark = 'Take it back';

  // The picker.
  static String pickerTitle(LunchSlot slot, String day) =>
      '${slotName(slot)} for $day';
  static String suggestedFor(String name) => 'Suggested for $name';
  static String dislikedBy(String name) => '$name does not like';
  static String notSafeFor(String name) => 'Not safe for $name';
  static const somethingElse = 'Something else';
  static const takeItOut = 'Take it out';
  static const libraryEmpty =
      'Nothing in the library for this slot yet. Add the first one above.';
  static String eatenTimes(int times) =>
      times == 1 ? 'Eaten once' : 'Eaten $times times';
  static String leftTimes(int times) =>
      times == 1 ? 'Left once' : 'Left $times times';
  static const likesIt = 'Likes it';
  static String alreadyThisWeek(int times) =>
      times == 1 ? 'Already in 1 box' : 'Already in $times boxes';

  static String contains(Iterable<String> allergens) =>
      'Contains ${allergens.join(', ')}';

  static String allergicTo(String allergen) => 'Allergic to $allergen';
  static String nutRule(Set<NutFreeReason> reasons) =>
      FamilyCopy.nutFreeBecause(NutFreeReason.values.where(reasons.contains));

  // The item sheet.
  static const newItemTitle = 'Add to the library';
  static const editItemTitle = 'Edit item';
  static const itemName = 'What is it?';
  static const itemNameHint = 'Vetkoek, sushi, leftover pasta…';
  static const itemNameTooLong = 'Keep it under 60 letters.';
  static const itemSlot = 'Which part of the box';
  static const itemContains = 'What is in it';
  static const itemContainsHelp =
      'Tick every allergen it has. This is what keeps it out of a box it '
      'must not go in.';
  static const itemPrepAhead = 'Make it ahead on Sunday';
  static const itemPrepNote = 'How to prep it (optional)';
  static const itemPrepNoteHint = 'Bake a dozen, freeze half';
  static const itemPrepNoteTooLong = 'Keep it under 140 letters.';
  static const addAndPack = 'Add and pack it';
  static const addItem = 'Add it';
  static const saveItem = 'Save';
  static String putAway(String item) => 'Put $item away';
  static String bringBack(String item) => 'Bring $item back';

  // The library screen.
  static const libraryTitle = 'Lunch library';
  static const openLibrary = 'Library';
  static const librarySubtitle = 'Everything a box can hold';
  static const putAwayItems = 'Not offered right now';
  static const libraryLoadingSeed =
      'Setting up your library with lunch-box favourites…';
  static const prepAheadTag = 'Sunday prep';

  // Go-to boxes.
  static String favouritesFor(String name) => '$name’s go-to boxes';
  static const favouriteName = 'Call it';
  static const noFavourites =
      'No go-to boxes yet. Pack a box they love, then save it from the day’s '
      'menu — it comes round again when you fill a week.';
  static const favouriteUnsafe = 'No longer safe for them';
  static String removeFavourite(String name) => 'Remove $name';

  // The Sunday prep list.
  static const prepTitle = 'Sunday prep';
  static const openPrep = 'Sunday prep';
  static String prepFor(String day) => 'Sunday $day, for the week ahead';
  static const prepBatch = 'Make ahead';
  static const prepOnHand = 'Have in the house';
  static const prepEmptyTitle = 'Nothing packed for this week yet';
  static const prepEmptyBody =
      'Plan the week’s boxes and everything they need gathers here — what to '
      'make on Sunday first.';
  static const backToLunches = 'Back to lunches';
  static String prepProgress(int done, int total) => '$done of $total ready';
  static String portions(int count) =>
      count == 1 ? 'For 1 box' : 'For $count boxes';
  static String prepRowLabel(String name, bool isDone) =>
      isDone ? '$name, ready. Untick' : '$name. Tick when ready';

  // The kid's tablet.
  static const kidLunchTitle = 'My lunch box';
  static const kidLunchNothing = 'Nothing packed yet — ask a grown-up.';

  static String problem(LunchProblem problem) => switch (problem) {
    LunchProblem.unsafeForChild =>
      'That cannot go in — it is not safe for them. Their allergies and '
          'school rules are on their profile.',
    LunchProblem.refusedByRules =>
      'NestPrep would not pack that. Their allergies or school rules may have '
          'just changed — check their profile and try again.',
    LunchProblem.tooManyFavourites =>
      'That is as many go-to boxes as one child can keep. Remove one first.',
    LunchProblem.nameTooLong =>
      'That name is too long for a go-to box. Keep it under 40 letters.',
    LunchProblem.cardNotDrawn =>
      'The card could not be made on this phone. Try again in a moment.',
    LunchProblem.shareUnavailable =>
      'The share sheet would not open. Try again in a moment.',
    LunchProblem.printUnavailable =>
      'This phone cannot print from here. Send the PDF instead and print it '
          'from there.',
  };
}
