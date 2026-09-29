/// What kind of room a room is — which picks its icon, and nothing else.
///
/// The names are stored as they are written here, and
/// `rules/firestore/household/home_care.rules` lists the same ones;
/// `home_care_vocabulary_matches_the_rules_test.dart` reads both.
enum RoomKind {
  kitchen,
  lounge,
  dining,
  bedroom,
  kidsRoom,
  bathroom,
  laundry,
  office,
  outside,
  garage,
  other,
}
