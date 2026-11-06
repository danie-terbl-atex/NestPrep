import '../../features/welcome_tour/model/tour_place.dart';
import '../../features/welcome_tour/model/tour_premium.dart';
import '../../features/welcome_tour/model/tour_target.dart';
import 'app_copy.dart';
import 'grocery_plan_copy.dart';

/// Every word the welcome tour says (`FE-19`, welcome-tour ADR-0002): one
/// title and a line or two per component it spotlights. A component keeps
/// the name its own screen gives it; only the tour's own lines live here.
abstract final class TourCopy {
  static const skip = 'Skip';
  static const next = 'Next';
  static const back = 'Back';
  static const done = 'Done';
  static const planFirstLunch = 'Plan your first lunch';
  static const replay = 'Replay the tour';

  /// Where in the tour, on the callout.
  static String stepOf(int number, int count) => '$number of $count';

  static String chapter(TourPlace place) => switch (place) {
    TourPlace.today => AppCopy.tabToday,
    TourPlace.calendar => AppCopy.tabCalendar,
    TourPlace.lunch || TourPlace.meals => AppCopy.tabFood,
    TourPlace.todos || TourPlace.groceries => AppCopy.tabLists,
    TourPlace.more => MoreCopy.tab,
  };

  /// [isLookOnly]: the person can see this but not change it.
  static String title(TourTarget target, {required bool isLookOnly}) =>
      switch (target) {
        TourTarget.tabBar => 'Five places, one family',
        TourTarget.todayLunch => TodayCopy.lunchEyebrow,
        TourTarget.bell => 'One calm morning digest',
        TourTarget.accountMenu => 'Your account',
        TourTarget.lunchChildSwitcher => 'A week for each child',
        TourTarget.lunchDayPills => 'Monday to Friday',
        TourTarget.lunchDay when isLookOnly => 'The day’s box',
        TourTarget.lunchDay => 'Tap the day to pack it',
        TourTarget.lunchNoChildren => 'Start here',
        TourTarget.lunchPlanner => LunchCopy.planWholeWeek,
        TourTarget.lunchPlanMyWeek => 'Let Twig plan',
        TourTarget.lunchTools => LunchCopy.toolsTitle,
        TourTarget.lunchPrep => LunchCopy.openPrep,
        TourTarget.lunchBudget => LunchPlanningCopy.openBudget,
        TourTarget.calendarViews => 'The whole family’s month',
        TourTarget.mealsViews => 'Recipes for every meal',
        TourTarget.listsSwitch => 'To do and groceries',
        TourTarget.groceryPlans => GroceryPlanCopy.title,
        TourTarget.morePeople => MoreCopy.peopleTitle,
        TourTarget.moreFamily => FamilyCopy.title,
      };

  static String body(
    TourTarget target, {
    required bool isLookOnly,
    required TourPremium premium,
  }) => switch (target) {
    TourTarget.tabBar =>
      'Everything you can open lives in this bar. Today is home: your day '
          'at a glance.',
    TourTarget.todayLunch =>
      'What each child is having today. Tap it to open their week.',
    TourTarget.bell =>
      'Notifications land here, with one summary each morning.',
    TourTarget.accountMenu =>
      'Switch household, see your account, sign out — and replay this tour '
          'any time.',
    TourTarget.lunchChildSwitcher =>
      'Each child has their own week. Switch between them here.',
    TourTarget.lunchDayPills => 'Pick a school day to see that day’s box.',
    TourTarget.lunchDay when isLookOnly =>
      'Five parts to every box: a main, fruit, veg, a snack and a treat. '
          'Tap it to see the day in full.',
    TourTarget.lunchDay =>
      'Tap a part to pick. What suits this child comes first; what they’re '
          'allergic to never shows.',
    TourTarget.lunchNoChildren =>
      'Add your children and their allergies once, in Family profiles. Every '
          'lunch follows them.',
    TourTarget.lunchPlanner =>
      'Plan the week packs every empty part in one go, from go-to or '
          'ready-made boxes. It never replaces what you packed.',
    TourTarget.lunchPlanMyWeek => _premium(
      premium,
      'Or let Twig, NestPrep’s AI helper, plan the week from what your shop '
      'sells and fill your cart.',
    ),
    TourTarget.lunchTools =>
      'The library, sharing the week, the pantry and kid picks all live here.',
    TourTarget.lunchPrep => _premium(
      premium,
      'Everything the week’s boxes need, in one list to prep on Sunday.',
    ),
    TourTarget.lunchBudget => _premium(
      premium,
      'What a box and the week cost, with cheaper swaps they’ll still eat.',
    ),
    TourTarget.calendarViews when isLookOnly =>
      'Everyone’s events, birthdays and synced calendars, a dot in each '
          'person’s colour. Switch to the week for the detail.',
    TourTarget.calendarViews =>
      'Everyone’s events, birthdays and synced calendars in one month. Tap '
          'a day to see it, or type “Soccer Tuesdays at 5” to add one.',
    TourTarget.mealsViews when isLookOnly =>
      'Family recipes for breakfast, lunch and dinner, and what’s planned '
          'this week.',
    TourTarget.mealsViews =>
      'Find a recipe, scale it for your family, and add it to this week in '
          'a tap. Lunchboxes are one chip away.',
    TourTarget.listsSwitch =>
      'To do has due dates, repeats and who it’s for. Groceries is one '
          'shared list.',
    TourTarget.groceryPlans =>
      'The week’s lunches and meals add what they need to the list — you '
          'choose what goes on.',
    TourTarget.morePeople when isLookOnly =>
      'Everyone in this household, and what each of them looks after.',
    TourTarget.morePeople =>
      'Invite the people who help, and choose what each of them can see.',
    TourTarget.moreFamily when isLookOnly =>
      'The children’s allergies and what they eat, so you always know '
          'what’s safe.',
    TourTarget.moreFamily =>
      'Start here: allergies, likes, medication and school for each person. '
          'The lunch box reads them.',
  };

  static String _premium(TourPremium premium, String line) => switch (premium) {
    TourPremium.included => 'Yours with Premium. $line',
    TourPremium.offered => '$line Part of Premium.',
    TourPremium.none => line,
  };
}
