import '../../features/family_profiles/model/allergen.dart';
import '../../features/recipes/model/recipe_context.dart';
import '../../features/recipes/model/recipe_course.dart';
import '../../features/recipes/model/recipe_form.dart';
import '../failure/app_failure.dart';
import 'family_copy.dart';

abstract final class OwnRecipeCopy {
  // Finding them, and the upsell.

  static const addTitle = 'Add your own recipe';
  static const unreadable =
      'Your own recipes didn’t load. The rest of the recipes are all here.';

  // The builder.

  static const newTitle = 'Add a recipe';
  static const editTitle = 'Edit recipe';
  static const save = 'Save recipe';
  static const saved = 'Recipe saved.';
  static const savedButWeekIsOld =
      'Recipe saved, but your week still has the old ingredients. Add it to '
      'the week again to bring them up to date.';
  static const cutShort =
      'This recipe was too long to fit, so we kept what we could. Check it '
      'against the original before you save.';
  static const openOriginal = 'Open the original';
  static const fixTheMarked =
      'A few things still need you. They’re marked in red.';
  static const leaveTitle = 'Leave without saving?';
  static const leaveMessage = 'Your changes to this recipe won’t be kept.';
  static const leaveConfirm = 'Leave';
  static const leaveCancel = 'Keep editing';
  static const notYours =
      'You can read and cook the recipes here, but you can’t add or change '
      'them.';

  static const photosHeader = 'Photos';
  static const photosHint =
      'The first one is the cover. They stay on your phone until you save.';
  static const takePhoto = 'Take a photo';
  static const choosePhotos = 'Choose photos';
  static const coverTag = 'Cover';
  static const makeCover = 'Make cover';
  static String removePhoto(int number) => 'Remove photo $number';
  static String photoNumbered(int number, int of) => 'Photo $number of $of';

  static const name = 'Name';
  static const nameHint = 'Gran’s bobotie';
  static const description = 'Description';
  static const descriptionHint = 'What is it, and who asks for it?';

  static const mealsHeader = 'Which meals is it for?';
  static String mealName(RecipeContext context) => switch (context) {
    RecipeContext.breakfast => 'Breakfast',
    RecipeContext.lunch => 'Lunch',
    RecipeContext.dinner => 'Dinner',
    RecipeContext.lunchBox => 'Lunch box',
  };
  static String courseName(RecipeCourse course) => switch (course) {
    RecipeCourse.main => 'Main',
    RecipeCourse.side => 'Side',
    RecipeCourse.dessert => 'Dessert',
    RecipeCourse.snack => 'Snack',
  };
  static String courseFor(RecipeContext context, RecipeCourse course) =>
      '${courseName(course)} at ${mealName(context).toLowerCase()}';

  static const numbersHeader = 'How many, how long';
  static const serves = 'Serves';
  static const prep = 'Prep (min)';
  static const cook = 'Cook (min)';

  static const addIngredient = 'Add ingredient';
  static const addHeading = 'Add heading';
  static const editIngredient = 'Change ingredient';
  static const saveIngredient = 'Save ingredient';
  static const done = 'Done';
  static const ingredientNote = 'Note (optional)';
  static const ingredientNoteHint = 'Finely chopped';
  static const amountTooBig = 'That’s more than a recipe can hold. Check it?';
  static const headingLabel = 'Heading';
  static const headingHint = 'For the sauce';
  static const saveHeading = 'Save heading';
  static String removeIngredient(String name) => 'Remove $name';
  static String removeHeading(String heading) => 'Remove the heading $heading';
  static String ingredientsFull(int limit) =>
      '$limit ingredients is the most a recipe can hold.';

  static const addStep = 'Add step';
  static const stepLabel = 'Step';
  static const stepHint = 'Fry the onions until golden.';
  static const saveStep = 'Save step';
  static String removeStep(int number) => 'Remove step $number';
  static String stepsFull(int limit) =>
      '$limit steps is the most a recipe can hold.';

  static const moveUp = 'Move up';
  static const moveDown = 'Move down';
  static const dragToMove = 'Drag to move';

  static const tips = 'Tips';
  static const tipsHint =
      'What you’d tell a friend making it for the first '
      'time.';

  static const allergensBuilderNote =
      'We read these from your words as you type, and we can miss things. Tap '
      'to add any we haven’t found. What we find here stays on.';
  static String allergenFound(Allergen allergen) =>
      '${FamilyCopy.allergenName(allergen)}, found in the recipe’s words';
  static String allergenAdded(Allergen allergen) =>
      '${FamilyCopy.allergenName(allergen)}, added by you';
  static String allergenToAdd(Allergen allergen) =>
      'Add ${FamilyCopy.allergenName(allergen).toLowerCase()}';

  static String missing(RecipeFormProblem problem) => switch (problem) {
    RecipeFormProblem.noName => 'Give the recipe a name.',
    RecipeFormProblem.noMeal => 'Choose at least one meal.',
    RecipeFormProblem.noIngredients => 'Add at least one ingredient.',
    RecipeFormProblem.noSteps => 'Add at least one step.',
    RecipeFormProblem.badServings => 'A number from 1 to 24.',
    RecipeFormProblem.badPrepMinutes ||
    RecipeFormProblem.badCookMinutes => 'Up to 1440 minutes.',
  };

  // The recipe's page.

  static const edit = 'Edit';
  static const delete = 'Delete';
  static const deleteTitle = 'Delete this recipe?';
  static String deleteMessage(String name) =>
      '$name and its photos go for everyone in your household. Anything '
      'you’ve planned stays on your week as a plain meal.';
  static const deleteConfirm = 'Delete recipe';
  static const deleteCancel = 'Keep it';
  static const deleted = 'Recipe deleted.';
  static String fromSource(String source) => 'From $source';

  // Never an all-clear (recipes ADR-0007 §5).

  static const allergensFound =
      'We read this from the recipe’s words, so it can miss things. Check it '
      'yourself for anyone with an allergy.';
  static const allergensNoneFound =
      'We didn’t find any allergens in this recipe’s words, but that’s no '
      'all-clear: we only read English. Check it yourself for anyone with an '
      'allergy.';

  static String problem(OwnRecipeProblem problem) => switch (problem) {
    OwnRecipeProblem.householdRecipesOff =>
      'Adding your own recipes isn’t switched on just now. Your recipes are '
          'still here.',
    OwnRecipeProblem.mealsNotShared =>
      'You can’t change meals in this household. Ask a parent.',
    OwnRecipeProblem.recipeLimitReached =>
      'Your household has 300 recipes, which is the most it can keep. Delete '
          'one to add another.',
    OwnRecipeProblem.notOwnRecipe =>
      'That recipe isn’t one your household added, so it can’t be changed.',
    OwnRecipeProblem.recipePhotoMissing =>
      'A photo didn’t finish uploading. Please try saving again.',
    OwnRecipeProblem.sourceLinkNotPublic =>
      'That link isn’t a public web page, so it can’t be kept with the recipe.',
    OwnRecipeProblem.documentPageUnreadable ||
    OwnRecipeProblem.documentUnreadable =>
      'NestPrep can’t read that PDF. It may be locked with a password or '
          'damaged. Try another one.',
    OwnRecipeProblem.documentTooLong =>
      'That PDF has more than 50 pages. Save the pages with the recipes as '
          'a shorter PDF and try that.',
    OwnRecipeProblem.documentTooLarge =>
      'That PDF is too big to read on your phone. Try a smaller one.',
    OwnRecipeProblem.documentPickerUnavailable =>
      'Your files wouldn’t open. Please try again.',
    OwnRecipeProblem.documentShareGone =>
      'That PDF is no longer here. Share it again, or choose it below.',
    OwnRecipeProblem.recipePhotoUnreadable =>
      'NestPrep can’t read that picture. Try another one.',
    OwnRecipeProblem.recipePhotoTooLarge =>
      'That picture is too big to keep, even made smaller. Try another one.',
    OwnRecipeProblem.recipePhotoRefused =>
      'NestPrep needs your camera or photos for that. You can allow it in your '
          'phone’s settings.',
    OwnRecipeProblem.recipePhotoPickerUnavailable =>
      'The camera or your photos wouldn’t open. Please try again.',
  };
}
