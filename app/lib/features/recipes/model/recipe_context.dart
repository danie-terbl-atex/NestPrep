/// Where a recipe is meant to be eaten — the vocabulary of `recipes/{id}`'s
/// `contexts` and the keys of its `placement`. A recipe is one domain shared
/// by every meal NestPrep plans: the lunch box names the compartment it
/// fills, and breakfast, lunch and dinner the course (recipes ADR-0003 §1).
enum RecipeContext {
  lunchBox,
  breakfast,
  lunch,
  dinner;

  /// The context a stored name means, or null for one this build does not
  /// know (`BE-10`).
  static RecipeContext? fromName(String name) =>
      values.where((context) => context.name == name).firstOrNull;

  /// A family meal on the meal plan, rather than a packed lunch.
  bool get isMeal => this != lunchBox;
}
