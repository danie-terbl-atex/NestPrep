import { CATALOGUE_RECIPES_DIR, readCatalogueRecipes } from './catalogue_recipe_files';
import { LUNCH_MAIN_RECIPES } from './lunch_main_recipes';
import { LUNCH_SNACK_RECIPES } from './lunch_snack_recipes';
import { LUNCH_TREAT_RECIPES } from './lunch_treat_recipes';
import { recipeSource, type Recipe } from './recipe';

/**
 * Every recipe NestPrep publishes, parsed (ENG-09) — the one source the
 * catalogue seed writes to `recipes/{id}` and starter boxes refer to (recipes
 * ADR-0001): the lunch box's own recipes, kept here beside the starter boxes
 * that name them, and the meal recipes authors write as JSON under
 * `catalogue/recipes/` (ADR-0003). Parsed on load: a recipe that breaks the
 * shape, or two sharing an id, fails the build's tests and the seed, never a
 * household.
 */
export function recipeCatalogue(
  sources: readonly Recipe[] = catalogueRecipeSources(),
): ReadonlyMap<string, Recipe> {
  const recipes = sources.map((source) => recipeSource.parse(source));
  const catalogue = new Map(recipes.map((recipe) => [recipe.id, recipe]));
  if (catalogue.size !== recipes.length) throw new Error('a recipe id is used twice');
  return catalogue;
}

/** The lunch box's recipes and every recipe written under [recipesDir]. */
export function catalogueRecipeSources(recipesDir: string = CATALOGUE_RECIPES_DIR): Recipe[] {
  return [
    ...LUNCH_MAIN_RECIPES,
    ...LUNCH_SNACK_RECIPES,
    ...LUNCH_TREAT_RECIPES,
    ...readCatalogueRecipes(recipesDir),
  ];
}
