enum RecipeOrigin {
  typed,
  link,
  photo,
  document;

  static RecipeOrigin fromName(String? name) =>
      values.firstWhere((origin) => origin.name == name, orElse: () => typed);
}
