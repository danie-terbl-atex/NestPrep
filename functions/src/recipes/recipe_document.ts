import { ALLERGENS, type Allergen } from '../plan_week/food_safety';
import type { Recipe } from './recipe';
import type { RecipePhotoDocument, RecipePhotoPaths } from './recipe_photo';

/** Who wrote a catalogue recipe; household recipes say `ai` (recipes ADR-0001, ADR-0002). */
export const NESTPREP_SOURCE = 'nestprep';

export type RecipeDocument = Omit<Recipe, 'id' | 'photo'> & {
  readonly source: typeof NESTPREP_SOURCE;
  readonly photo: RecipePhotoDocument | null;
};

/** Allergen codes in the family-profiles order, so an unchanged recipe compares equal. */
export function catalogueAllergens(codes: readonly Allergen[]): Allergen[] {
  return ALLERGENS.filter((code) => codes.includes(code));
}

/**
 * What `recipes/{id}` holds for [recipe], before the publisher adds `status`,
 * `version` and `updatedAt` — the stored shape, spelled out so a field added
 * to the source is a decision about the document too (BE-02). [photoPaths] are
 * where the seed published the recipe's photo files; a recipe with a photo
 * and nowhere it was published throws rather than store half a picture.
 */
export function recipeDocument(
  recipe: Recipe,
  photoPaths: RecipePhotoPaths | null,
): RecipeDocument {
  return {
    name: recipe.name,
    summary: recipe.summary,
    about: recipe.about,
    source: NESTPREP_SOURCE,
    cuisine: recipe.cuisine,
    contexts: recipe.contexts,
    placement: recipe.placement,
    tags: recipe.tags,
    allergens: catalogueAllergens(recipe.allergens),
    dietTags: recipe.dietTags,
    ingredients: recipe.ingredients.map(({ name, quantity, unit, note, group }) => ({
      name,
      quantity,
      unit,
      note,
      group,
    })),
    steps: recipe.steps,
    servings: recipe.servings,
    prepMinutes: recipe.prepMinutes,
    cookMinutes: recipe.cookMinutes,
    difficulty: recipe.difficulty,
    prepAhead: recipe.prepAhead,
    prepNote: recipe.prepNote,
    photo: photoDocument(recipe, photoPaths),
  };
}

function photoDocument(
  recipe: Recipe,
  photoPaths: RecipePhotoPaths | null,
): RecipePhotoDocument | null {
  if (recipe.photo === null) return null;
  if (photoPaths === null) throw new Error(`recipe ${recipe.id} has a photo nobody published`);
  return {
    card: photoPaths.card,
    hero: photoPaths.hero,
    credit: recipe.photo.credit,
    licence: recipe.photo.licence,
    sourceUrl: recipe.photo.sourceUrl,
    generated: recipe.photo.generated,
  };
}
