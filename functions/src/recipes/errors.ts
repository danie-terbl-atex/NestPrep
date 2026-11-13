import { HttpsError, type FunctionsErrorCode } from 'firebase-functions/v2/https';

export const OWN_RECIPE_REFUSALS = {
  householdRecipesOff: ['failed-precondition', 'Household recipes are switched off.'],
  mealsNotShared: ['permission-denied', 'You cannot change meals in this household.'],
  recipeLimitReached: ['resource-exhausted', 'This household has as many recipes as it may keep.'],
  notOwnRecipe: ['failed-precondition', 'That recipe is not one this household added.'],
  recipePhotoMissing: ['failed-precondition', 'A photo of that recipe was not uploaded.'],
  sourceLinkNotPublic: ['invalid-argument', 'A recipe links to public web pages only.'],
  documentPageUnreadable: ['invalid-argument', 'A page of that PDF could not be read.'],
} as const satisfies Record<string, readonly [FunctionsErrorCode, string]>;

export type OwnRecipeRefusal = keyof typeof OWN_RECIPE_REFUSALS;

export function refuseOwnRecipe(reason: OwnRecipeRefusal): HttpsError {
  const [code, message] = OWN_RECIPE_REFUSALS[reason];
  return new HttpsError(code, message, { reason });
}
