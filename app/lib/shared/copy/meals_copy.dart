/// The Meals tab's own words (design-system ADR-0015): its two views and
/// the line under its name. The recipes' words are `RecipeCopy`, the week's
/// `AppCopy`'s `meals…` (`FE-19`).
abstract final class MealsCopy {
  static const recipes = 'Recipes';
  static const thisWeek = 'This week';
  static const recipesSubtitle = 'Breakfast, lunch and dinner ideas';
  static const pickRecipe = 'Pick a NestPrep recipe';
  static const orTypeYourOwn = 'or type your own';
  static const pickerTitle = 'Pick a recipe';
  static const pickerBack = 'Back to the week';
}
