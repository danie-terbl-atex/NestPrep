/// The five compartments of a school lunch box (lunch-box ADR-0001), in the
/// order a box is packed and read. The stored name is the enum's name, and
/// `firestore.rules` spells the same five — `lunch_vocabulary_matches_the_rules
/// _test.dart` holds them together.
enum LunchSlot {
  main,
  fruit,
  veg,
  snack,
  treat;

  /// The slot a stored name means, or null for one this build does not know.
  static LunchSlot? fromName(String name) =>
      values.where((slot) => slot.name == name).firstOrNull;

  /// Auto-fill packs a treat on Fridays only; every other slot every school
  /// day (lunch-box ADR-0003). A parent adds a treat to any day by hand.
  bool isAutoFilledOn(int isoWeekday) =>
      this != treat || isoWeekday == DateTime.friday;
}
