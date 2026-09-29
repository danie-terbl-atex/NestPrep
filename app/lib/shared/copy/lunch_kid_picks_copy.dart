/// Every word kid picks says (lunch-box ADR-0008), `FE-19` — the parent's
/// side first, then the child's, which is written to be read by a child.
abstract final class LunchKidPicksCopy {
  // The parent's screen.
  static const title = 'Kid picks';
  static String subtitle(String name) => 'Let $name choose';
  static const introBody =
      'Pick two or three things for a part of the box and your child chooses '
      'one — on their own tablet, or on your phone. Only what is safe for '
      'them can be offered.';
  static const suggestOptions = 'Suggest options for the week';
  static String letChoose(String name) => 'Let $name choose now';
  static const tabletHint =
      'If they have a tablet signed in, the choices are waiting there too.';
  static const weekOver = 'This week is over — nothing left to choose.';
  static const setOptions = 'Choose options';
  static String optionsList(Iterable<String> names) => names.join(' · ');
  static const packedByYou = 'Packed — no choice here';
  static String chose(String name, String item) => '$name chose $item';
  static const waiting = 'Waiting for a pick';

  // The options sheet.
  static String optionsTitle(String slot, String day) => '$slot on $day';
  static const optionsHelp = 'Choose two or three. Only safe ones are here.';
  static String optionsCount(int count) => '$count of 3 chosen';
  static const saveOptions = 'Offer these';
  static const clearOptions = 'No choice here';
  static const noSuggestions =
      'Not enough safe things in the library for this part of the box yet.';

  // The child's side.
  static const kidCardTitle = 'Pick your lunch!';
  static String kidCardBody(int days) => days == 1
      ? 'There is 1 day to choose.'
      : 'There are $days days to choose.';
  static const kidCardAllDone = 'All chosen. Yum!';
  static const kidCardOpen = 'Let’s choose';
  static const chooserTitle = 'Pick your lunch';
  static String chooserTitleFor(String name) => '$name, pick your lunch!';
  static String progress(int chosen, int total) => '$chosen of $total picked';
  static const dayDone = 'All done! Your lunch box is ready.';
  static const nothingToChoose = 'Nothing to choose yet';
  static const nothingToChooseBody =
      'A grown-up picks some things first. Then come back and choose!';
  static const handBack = 'All done — give the phone back';
  static String optionLabel(String item, bool isChosen) =>
      isChosen ? '$item, chosen' : 'Choose $item';
  static const today = 'Today';
}
