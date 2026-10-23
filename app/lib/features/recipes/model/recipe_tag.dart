/// The fixed vocabulary a catalogue recipe is tagged from (recipes ADR-0003
/// §2), so a filter is a chip and never free text. Stored by [name].
enum RecipeTag {
  braai,
  potjie,
  onePot,
  quick,
  budget,
  kidFriendly,
  comfort,
  festive,
  baking,
  traditional,
  capeMalay,
  streetFood,
  vegetableForward;

  /// The tag a stored name means, or null for one this build does not know —
  /// skipped, never a reason to lose the recipe (`BE-10`).
  static RecipeTag? fromName(String name) =>
      values.where((tag) => tag.name == name).firstOrNull;
}
