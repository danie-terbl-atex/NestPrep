/// Where a grocery line came from when a person did not type it (lunch-box
/// ADR-0006): the lunch plans, or the pantry falling short of them. The
/// stored name is the enum's name, and the groceries rules spell the same
/// list. A line somebody typed has none.
enum GrocerySource {
  lunch,
  pantry;

  /// The source a stored name means, or null for one this build does not
  /// know (`BE-10`).
  static GrocerySource? fromName(String? name) =>
      values.where((source) => source.name == name).firstOrNull;
}
