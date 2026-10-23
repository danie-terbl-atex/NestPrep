/// The Meals tab's two views under one header (design-system ADR-0015): the
/// recipes to choose from, which it opens on, and the week they go into.
/// Held in the route's `view` query, so a link or a back press lands on the
/// one it named (`FE-07`, `FE-17`).
enum MealsView {
  recipes,
  week;

  /// The view a `view` query names; anything else is the recipes.
  static MealsView fromQuery(String? value) =>
      values.where((view) => view.name == value).firstOrNull ?? recipes;
}
