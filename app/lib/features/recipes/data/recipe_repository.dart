import '../model/recipe.dart';
import '../model/recipe_link.dart';

/// Recipes, read-only: NestPrep's published ones and a household's own
/// (recipes ADR-0001, ADR-0002). Anything that shows or plans a recipe reads
/// it through this — the lunch box's ready-made boxes and its recipe sheet,
/// and the Meals tab's recipes (recipes ADR-0003).
abstract interface class RecipeRepository {
  /// Every published recipe, in name order — one bounded read the offline
  /// cache keeps (recipes ADR-0003 §7). A recipe this build cannot read is
  /// left out, never the whole list; a read that fails is an `AppFailure`
  /// on the stream.
  Stream<List<Recipe>> watchCatalogue();

  /// How many recipes one catalogue read asks for: the rules' list cap. Past
  /// it, paging per context replaces the single read (§7).
  static const catalogueLimit = 200;

  /// The published recipes among [ids], in no particular order. One that is
  /// missing, retired or unreadable by this build is left out, never a
  /// failure: whatever named it shows its own words instead.
  Future<List<Recipe>> fetchByIds(Set<String> ids);

  /// The one recipe [link] names in [householdId] — the catalogue's or the
  /// household's own — or null when it is missing, retired or unreadable by
  /// this build. A read that fails is an `AppFailure`.
  Future<Recipe?> fetchLinked(String householdId, RecipeLink link);
}
