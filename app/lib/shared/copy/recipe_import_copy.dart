import '../failure/app_failure.dart';

abstract final class RecipeImportCopy {
  // The four ways in.

  static const waysTitle = 'Add a recipe';
  static const typeTitle = 'Type it';
  static const typeBody = 'Write it in yourself, from memory or a cookbook.';
  static const linkTitle = 'From a link';
  static const linkBody = 'Paste a web page and we’ll fill the recipe in.';
  static const snapTitle = 'Snap it';
  static const snapBody = 'Photos of a page or card, or screenshots.';
  static const pdfTitle = 'From a PDF';
  static const pdfBody =
      'A cookbook or booklet. Add every recipe in it at once.';

  // Starting.

  static const linkScreenTitle = 'Add from a link';
  static const linkHeroTitle = 'Paste the recipe’s link';
  static const linkHeroBody =
      'NestPrep reads the page and fills in a recipe for you to check. Nothing '
      'is saved until you tap Save.';
  static const linkLabel = 'Link to the recipe';
  static const linkHint = 'https://';
  static const paste = 'Paste';
  static const read = 'Read this recipe';
  static const notAPublicLink =
      'That doesn’t look like a public web page. Paste the whole link, starting '
      'with https://';

  static const snapScreenTitle = 'Snap a recipe';
  static const snapHeroTitle = 'Snap the recipe';
  static const snapHeroBody =
      'Photos of a cookbook or a recipe card, or screenshots of a page. Add as '
      'many as the recipe takes. It comes back filled in for you to check, and '
      'nothing is saved until you tap Save.';
  static const takePhoto = 'Take a photo';
  static const choosePhoto = 'Choose photos or screenshots';
  static const takeAnother = 'Take another photo';
  static const chooseMore = 'Add more from your photos';
  static const readPhotos = 'Read this recipe';
  static const snapsHint =
      'Add every page or screenshot, in order. They’re read together as one '
      'recipe.';
  static const snapsFull = 'That’s as many as one recipe can take.';
  static const gettingPhotosReady =
      'Getting your photos ready. Long screenshots can take a little while.';
  static String snapsTitle(int count) =>
      count == 1 ? '1 photo' : '$count photos';
  static String snapNumbered(int number) => 'Photo $number';
  static String removeSnap(int number) => 'Take out photo $number';

  static const privacyTitle = 'What leaves your phone';
  static const linkPrivacyBody =
      'The text of this page, read by Google’s Gemini in Europe and not kept. '
      'Nothing about your family goes with it.';
  static const photoPrivacyBody =
      'Only the photos, read by Google’s Gemini in Europe and not kept. '
      'Nothing about your family goes with them.';

  // Working.

  static const readingPageTitle = 'Reading the page…';
  static const readingPageBody = 'Fetching the recipe from the site.';
  static const askingTitle = 'Writing it up…';
  static const askingBody =
      'Turning it into a recipe. This takes a few seconds.';

  // Stopped.

  static const snapScreenshot = 'Snap a screenshot';
  static const typeIt = 'Type it';
  static const tryAgain = 'Try again';
  static const tryAnotherPhoto = 'Change the photos';
  static const stoppedTitle = 'That didn’t work';
  static const notARecipePhotoTitle = 'That doesn’t look like a recipe';
  static const notARecipePhotoBody =
      'Closer, brighter photos of the whole recipe usually do it, or type it in '
      'yourself.';

  static String title(RecipeImportProblem problem) => switch (problem) {
    RecipeImportProblem.pageRefused => 'This site wouldn’t let us read it',
    RecipeImportProblem.pageNotFound => 'That page isn’t there any more',
    RecipeImportProblem.pageUnreachable => 'We couldn’t get to that page',
    RecipeImportProblem.linkNotPublic => 'That isn’t a public web page',
    RecipeImportProblem.noRecipe => 'That page doesn’t look like a recipe',
    RecipeImportProblem.photoUnreadable => 'That photo couldn’t be read',
    RecipeImportProblem.photosTooLong => 'That’s too much for one recipe',
  };

  static String problem(RecipeImportProblem problem) => switch (problem) {
    RecipeImportProblem.pageRefused =>
      'Some sites don’t let apps read their pages. Snap a screenshot of the '
          'recipe or type it in, and we’ll keep the link with it.',
    RecipeImportProblem.pageNotFound =>
      'The link may be old or have a typo. You can still snap a screenshot of '
          'the recipe or type it in.',
    RecipeImportProblem.pageUnreachable =>
      'The site was too slow, or too big to read, or your connection dropped. '
          'Try again, snap a screenshot, or type it in.',
    RecipeImportProblem.linkNotPublic =>
      'NestPrep only reads public web pages, never ones on a home or work '
          'network. Snap a screenshot of the recipe or type it in.',
    RecipeImportProblem.noRecipe =>
      'We couldn’t find a recipe on it. If there is one, snap a screenshot of '
          'it or type it in.',
    RecipeImportProblem.photoUnreadable =>
      'One of those isn’t a photo NestPrep can read, so it was left out.',
    RecipeImportProblem.photosTooLong =>
      'That’s more than one recipe can take, so the last photo was left out. '
          'Crop it to the recipe, or take out a photo you don’t need.',
  };

  // The builder's row of a page's pictures.

  static const picturesTitle = 'Pictures from the page';
  static const picturesHint =
      'The first is in. Tap to add others, or to take it out.';
  static String pictureNumbered(int number) => 'Picture $number from the page';
}
