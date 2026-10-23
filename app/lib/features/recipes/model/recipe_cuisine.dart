/// Where a dish is from, as far as finding it goes (recipes ADR-0003 §2).
enum RecipeCuisine {
  southAfrican,
  international;

  /// The cuisine a stored name means, or null for one this build does not
  /// know (`BE-10`).
  static RecipeCuisine? fromName(String? name) =>
      values.where((cuisine) => cuisine.name == name).firstOrNull;
}
