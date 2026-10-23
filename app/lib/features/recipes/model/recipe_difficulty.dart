/// How much a recipe asks of the cook (recipes ADR-0003 §2).
enum RecipeDifficulty {
  easy,
  medium,
  involved;

  /// The difficulty a stored name means, or null for one this build does not
  /// know (`BE-10`).
  static RecipeDifficulty? fromName(String? name) =>
      values.where((difficulty) => difficulty.name == name).firstOrNull;
}
