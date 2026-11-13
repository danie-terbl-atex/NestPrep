abstract final class RecipeDocumentCopy {
  static const screenTitle = 'Add from a PDF';
  static const pickerLabel = 'PDF';
  static const untitled = 'PDF';

  static const heroTitle = 'Choose a recipe PDF';
  static const heroBody =
      'A cookbook, a booklet or a magazine of up to 50 pages. NestPrep finds '
      'the recipes in it and you choose which to keep.';
  static const choose = 'Choose a PDF';
  static const chooseAnother = 'Choose another PDF';
  static String readShared(String name) => 'Read “$name”';
  static const sharedTitle = 'Read this PDF?';
  static String sharedBody(String name) =>
      'NestPrep finds the recipes in “$name” and you choose which to keep.';

  static const privacyTitle = 'Your PDF stays on your phone';
  static const privacyBody =
      'Only pictures of its pages are sent, read by Google’s Gemini in Europe '
      'and not kept. The PDF itself is never uploaded or stored: NestPrep lets '
      'go of it as soon as the recipes are read. Nothing about your family '
      'goes with it.';

  static const openingTitle = 'Reading your PDF…';
  static String openingBody(int done, int total) =>
      total == 0 ? 'Opening it.' : 'Page $done of $total.';
  static const scanningTitle = 'Finding the recipes…';
  static const scanningBody =
      'Looking through every page. This takes a few '
      'seconds.';
  static const draftingTitle = 'Writing it up…';
  static const draftingBody =
      'Turning it into a recipe, with its photo. This takes a few seconds.';

  static const nothingTitle = 'No recipes in this PDF';
  static const nothingBody =
      'We looked through every page and didn’t find a recipe, so nothing was '
      'added. The PDF wasn’t kept.';

  static String foundTitle(int count) => 'We found $count recipes';
  static String foundIn(String document) =>
      'In $document. Choose the ones to '
      'keep.';
  static String pagesOf(List<int> pages) => pages.length == 1
      ? 'Page ${pages.first}'
      : 'Pages ${pages.first}–${pages.last}';
  static String importAction(int count) =>
      count == 1 ? 'Add 1 recipe' : 'Add $count recipes';
  static String usesReads(int count, int? left) => left == null
      ? 'Each one is an AI read.'
      : 'Uses $count of your $left AI reads left this month.';
  static const savedStraight =
      'They go straight into Our recipes. Open one any time to change it or '
      'delete it.';
  static String mostAtOnce(int most) => 'You can add $most at a time.';

  static const importingTitle = 'Adding your recipes…';
  static const importingBody =
      'Each is read on its own pages and saved as soon as it’s ready.';
  static String doneTitle(int saved) => switch (saved) {
    0 => 'No recipes were added',
    1 => '1 recipe added to Our recipes',
    _ => '$saved recipes added to Our recipes',
  };
  static const doneBody = 'The PDF wasn’t kept.';
  static const seeThem = 'See our recipes';

  static const rowWaiting = 'Waiting';
  static const rowReading = 'Reading…';
  static const rowSaved = 'Added';
  static const rowNotARecipe = 'Not a recipe after all, so not added';
  static const rowUnfinished = 'Some of it is missing. Finish it to add it.';
  static const finishIt = 'Finish it';
  static const tryAgain = 'Try again';

  static const leaveTitle = 'Stop adding recipes?';
  static const leaveMessage =
      'Recipes already added stay in Our recipes. The rest won’t be added.';
  static const leaveConfirm = 'Stop';
  static const leaveCancel = 'Keep going';
}
