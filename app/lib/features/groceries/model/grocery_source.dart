/// Where a grocery line came from when a person did not type it (lunch-box
/// ADR-0006): the lunch plans, the pantry falling short of them, or a new
/// dinner's ingredients from plan my week (lunch-box ADR-0011). The
/// stored name is the enum's name, and the groceries rules spell the same
/// list. A line somebody typed has none.
enum GrocerySource {
  lunch,
  pantry,
  plan;

  /// The source a stored name means, or null for one this build does not
  /// know (`BE-10`).
  static GrocerySource? fromName(String? name) =>
      values.where((source) => source.name == name).firstOrNull;
}
