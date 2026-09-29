/// A handover's words (household ADR-0004).
abstract final class TwoHomesHandoverCopy {
  static const title = 'Handover';
  static String goesFromTo(String child, String from, String to) =>
      '$child goes from $from to $to';
  static const inTheBag = 'In the bag';
  static String packedCount(int packed, int total) =>
      '$packed of $total packed';
  static const addItem = 'Add';
  static const itemLabel = 'Something to pack';
  static const itemHint = 'School bag, inhaler, PE kit…';
  static const removeItem = 'Remove';
  static const suggestions = [
    'School bag',
    'Lunchbox',
    'Homework',
    'Medicine',
    'Comfort toy',
    'Charger',
  ];
  static const medicine = 'Medicine given';
  static const medicineHint = 'What, how much and when';
  static const homework = 'Homework';
  static const homeworkHint = 'What is due, and when';
  static const clothes = 'Clothes';
  static const clothesHint = 'Anything coming back, or needed';
  static const note = 'Anything else';
  static const noteHint = 'How the days went, what is coming up';
  static const save = 'Save for both homes';
  static const saved = 'Saved. Both homes see the same handover.';
  static String lastSavedBy(String home) => 'Last saved by $home';
  static const nothingYet = 'Nothing written for this handover yet.';
  static const readOnly =
      'A parent in this household writes handovers. You can read them here.';
}
