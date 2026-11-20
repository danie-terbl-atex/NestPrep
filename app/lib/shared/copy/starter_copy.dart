/// The examples a new household starts with, and the notice that clears them
/// (household ADR-0010). Each line that names a gesture names the one the row
/// really has: a to-do opens its buttons on a tap, a grocery item ticks on
/// its circle, and both open their editor when held.
abstract final class StarterCopy {
  static const taskComplete = 'Tap me, then press Complete';
  static const taskEdit = 'Hold me down to edit or remove';
  static const taskSlip = 'Sign the school permission slip';
  static const taskSlipNote =
      'An example. Give a to-do a day and a person, and it shows up on Today.';
  static const taskBins = 'Put the bins out';
  static const taskBinsNote =
      'An example of a to-do that repeats: this one comes back every week.';

  static const eventWelcome = 'Welcome to nestprep';
  static const eventWelcomeNote =
      'An example. Tap any event to open it, then Edit event to change or '
      'remove it.';
  static const eventSchoolRun = 'School run';
  static const eventSchoolRunNote =
      'An example that repeats on school days. Open it and choose Skip this '
      'one for a day off.';
  static const eventSwimming = 'Swimming lesson';
  static const eventSwimmingNote = 'Costume, towel, goggles.';
  static const eventBraai = 'Braai with the cousins';
  static const eventBraaiNote = 'Bring the rolls.';

  static const groceryTick = "Tick my circle when I'm in the trolley";
  static const groceryEdit = 'Hold me down to edit or remove';
  static const groceryMilk = 'Milk';
  static const groceryMilkQuantity = '2 l';
  static const groceryBread = 'Brown bread';
  static const groceryBananas = 'Bananas';
  static const groceryBananasQuantity = 'a bunch, for the lunchboxes';
  static const groceryRooibos = 'Rooibos tea';

  static const mealDinner = 'Spaghetti bolognese';
  static const mealMince = 'Beef mince';
  static const mealSpaghetti = 'Spaghetti';
  static const mealTomatoes = 'Chopped tomatoes';
  static const mealOnion = 'Onion';

  static const bannerMessage = 'These are examples to show you around.';
  static const bannerAction = 'Clear them';
  static const clearTitle = 'Clear the examples?';
  static const clearMessage =
      'This removes the example to-dos, events, groceries and dinner we added '
      'when you started, including any you have changed. Everything you added '
      'yourself stays.';
  static const clearConfirm = 'Clear the examples';
  static const clearCancel = 'Keep them';
}
