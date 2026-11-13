enum RecipeImportWay {
  link,
  snap;

  static RecipeImportWay fromQuery(String? name) =>
      name == snap.name ? snap : link;
}
