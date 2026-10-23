/// Where in a family meal a recipe goes (recipes ADR-0003 §1): a meal
/// context's placement names one of these, as the lunch box's names a
/// compartment.
enum RecipeCourse {
  main,
  side,
  dessert,
  snack;

  /// The course a stored name means, or null for one this build does not
  /// know (`BE-10`).
  static RecipeCourse? fromName(String? name) =>
      values.where((course) => course.name == name).firstOrNull;
}
