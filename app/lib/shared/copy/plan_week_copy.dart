import '../../features/family_profiles/model/allergen.dart';
import '../../features/groceries/model/product_match.dart';
import '../../features/plan_week/model/left_out_reason.dart';
import '../../features/plan_week/model/packing_preference.dart';
import '../../features/plan_week/model/plan_fallback.dart';
import '../../features/plan_week/model/treat_days.dart';
import '../../features/plan_week/model/treat_days_shortcut.dart';
import '../failure/app_failure.dart';
import '../money/money.dart';
import 'app_copy.dart' show AppCopy;
import 'checkers_copy.dart';
import 'family_copy.dart';

/// Every word *Plan my week* says (`FE-19`, lunch-box ADR-0012). Each step
/// says what it is doing and what NestPrep decided; the shop is the one the
/// brief chose (lunch-box ADR-0026), named in words.
abstract final class PlanWeekCopy {
  // ---- the way in, on the lunch board ----
  /// Twig is named as the one who plans, in words only: the row's picture is
  /// the chosen shop's logo (lunch-box ADR-0024, ADR-0026, design-system
  /// ADR-0014), so the body names the shop the title no longer does.
  static String entryTitle(String week) => 'Let Twig plan $week';
  static String entryBody(ProductRetailer shop) =>
      'Lunches for every child from what ${_name(shop)} sells, within your '
      'budget — you check each step.';
  static const premiumTag = 'Premium';

  // ---- the steps ----
  static const title = 'Plan my week';
  static String namedWeek(String name, String dates) => '$name · $dates';
  static List<String> stepNames(ProductRetailer shop) => [
    'Brief',
    'Ideas',
    'At ${_name(shop)}',
    'The week',
    'Done',
  ];
  static String stepOf(int number, String name) => 'Step $number of 5: $name';
  static const back = 'Back';

  // ---- 1. the brief ----
  static const briefHeadline = 'Who it’s for, and what to keep out';
  static const briefBody =
      'NestPrep plans around each child’s rules and what they like. '
      'Nothing is saved until you say so.';
  static const lunchesFor = 'Lunches for';
  static const noChildren =
      'Nobody is marked as a child yet. Mark one in Family to plan their '
      'lunches.';
  static String keptOut(String things) => 'Kept out: $things';
  static const nothingKeptOut = 'Nothing kept out';
  static String likes(String things) => 'Likes: $things';
  static const aiNeverSees =
      'The AI never sees allergies. NestPrep checks every idea and every '
      'product against them itself, before and after.';
  static const budgetHeader = 'Weekly lunch budget';
  static const budgetBody =
      'One total for all the children together, not per child — what '
      'you’d pay at the till.';
  static String budgetIs(String amount) => '$amount a week';
  static const noBudget =
      'No budget yet. The plan still says what the basket costs.';
  static const setBudget = 'Set a budget';
  static const changeBudget = 'Change the budget';
  static const packingHeader = 'How you like to pack';
  static const packingBody =
      'Pick what fits your mornings — the ideas follow it.';
  static String packingPreference(PackingPreference preference) =>
      switch (preference) {
        PackingPreference.readyMade => 'Prefer ready-made',
        PackingPreference.tenMinutes => '10 min prep, max',
        PackingPreference.airFryer => 'Pop in the air fryer',
        PackingPreference.nightBefore => 'Prep the night before',
        PackingPreference.sundayBatch => 'Sunday batch prep',
        PackingPreference.favourPrice => 'Favour price',
        PackingPreference.singleServe => 'Single-serve packs',
        PackingPreference.noFridge => 'No fridge needed',
        PackingPreference.healthier => 'Healthier picks',
      };
  static const slotsHeader = 'What goes in the box';
  static const slotsBody = 'Only these get filled. One always stays on.';

  /// Which school days this plan packs a treat on (lunch-box ADR-0025).
  static const treatDaysHeader = 'Treat days';
  static const treatDaysBody =
      'Which school days get a treat in this plan. You can still add one to '
      'any day on the lunch board.';
  static String treatDaysShortcut(TreatDaysShortcut shortcut) =>
      switch (shortcut) {
        TreatDaysShortcut.none => 'No treats',
        TreatDaysShortcut.fridaysOnly => 'Fridays only',
        TreatDaysShortcut.everyDay => 'Every day',
      };
  static const draftAction = 'Get lunch ideas';

  // ---- 2. ideas ----
  static const aisleTitle = 'Walking the lunchbox aisle…';
  static String aisleLine(ProductRetailer shop) =>
      'Reading ${_possessive(shop)} own lunchbox shelves near you and '
      'checking every product against each child’s rules.';
  static String aisleProgress(int read, int total) =>
      'Shelf ${read < total ? read + 1 : total} of $total';
  static const draftingTitle = 'Thinking up lunch ideas…';
  static const draftingLine =
      'Reading what each child likes and eats, the open compartments and the '
      'budget.';
  static String ideasHeadline(ProductRetailer shop) =>
      'What we’ll look for at ${_name(shop)}';
  static const ideasBody =
      'Remove anything you don’t want, or add your own. Struck-out ideas were '
      'left out by NestPrep for the reason shown.';
  static String fallbackIdeas(PlanFallbackReason reason) =>
      '${_without(reason)} So these ideas come from your own lunch library.';
  static String forChildren(String names) => 'For $names';
  static const leftOutForEveryone = 'Left out for everyone';
  static String removeIdea(String idea) => 'Remove $idea';
  static const addIdea = 'Add your own idea';
  static const addIdeaTitle = 'Your own idea';
  static const ideaField = 'What to look for';
  static const ideaHint = 'Yoghurt tubs, rice cakes…';
  static const ideaTooLong = 'Keep it under 60 letters.';
  static const ideaSave = 'Add';
  static const originOwn = 'Yours';
  static String originAisle(ProductRetailer shop) =>
      '${_name(shop)} lunchbox aisle';
  static String shelfKept(int count) =>
      '${_count(count, 'product', 'products')} kept from this shelf';
  static const shelfNothingKept = 'Nothing on this shelf suits anyone';
  static String aisleUnread(int count) =>
      '${_count(count, 'shelf', 'shelves')} of the lunchbox aisle could not '
      'be read, so the other ideas are searched instead.';
  static const noIdeas = 'No ideas left to look for';
  static const noIdeasBody = 'Add one of your own, or go back and try again.';
  static String searchAction(int count, ProductRetailer shop) =>
      'Look for ${_count(count, 'idea', 'ideas')} at ${_name(shop)}';

  // ---- 3. at the shop ----
  static String storeTitle(ProductRetailer shop) =>
      'Shopping at ${_name(shop)}…';
  static const storeLine =
      'Looking for each idea near you and checking every product against '
      'each child’s rules.';
  static String storeProgress(int searched, int total) =>
      'Idea ${searched < total ? searched + 1 : total} of $total';
  static String nothingKeptTitle(ProductRetailer shop) =>
      'Nothing at ${_name(shop)} fits';
  static const nothingKept =
      'Nothing was kept yet. Go back and try other ideas.';

  static String reason(LeftOutReason reason, {String? childName}) {
    final words = switch (reason.kind) {
      LeftOutKind.outOfStock => 'out of stock',
      LeftOutKind.soldByWeight => 'sold by weight',
      LeftOutKind.allergy => 'contains ${_allergen(reason.allergen)}',
      LeftOutKind.nutRule => 'contains nuts, and lunches are nut-free',
      LeftOutKind.otherAllergy => switch (reason.word) {
        final word? => 'mentions $word',
        null => 'mentions an allergy',
      },
      LeftOutKind.dislike => switch (reason.word) {
        final word? => 'doesn’t like $word',
        null => 'doesn’t like it',
      },
      LeftOutKind.unknownContents => 'no allergen information',
    };
    return childName == null ? words : '$childName: $words';
  }

  // ---- 4. the week ----
  static const buildingTitle = 'Building your week…';
  static String buildingLine(ProductRetailer shop) =>
      'Choosing from what ${_name(shop)} had, for each child, within the '
      'budget.';
  static String weekHeadline(String week) => 'Lunches for $week';
  static String fallbackWeek(PlanFallbackReason reason) =>
      '${_without(reason)} So the phone built it: the cheapest kept product '
      'for each idea, ideas taken in turn.';

  /// A phone-built week has no dishes: they need the AI's pack counts
  /// (lunch-box ADR-0021 §7).
  static const dishesNeedAi =
      'Dishes with recipes need the AI to cost their ingredients, so this '
      'week has products only.';

  /// A drafted main on the ideas list (ADR-0021 §3): what its recipe uses.
  static String dishMadeWith(int count, ProductRetailer shop) =>
      'A recipe with ${_count(count, 'ingredient', 'ingredients')}, '
      'each searched at ${_name(shop)}.';
  static String dropped(int count) =>
      '${_count(count, 'choice was', 'choices were')} left out because it '
      'did not fit a child’s rules.';
  static const alreadyPacked = 'Already packed';
  static const tapToSwap = 'Tap anything new to swap it or clear it.';

  /// Why the week shows no treat before Friday (lunch-box ADR-0003). The
  /// *balanced* reason is this line's framing, not the ADR's — it awaits
  /// Daniel's confirmation with ADR-0003.
  static const treatsFridaysOnly =
      'Treats go in on Fridays only, to keep the week’s lunches balanced. '
      'You can add one to any day on the lunch board.';

  /// Which days the week packs a treat on, once the brief chose other days
  /// than Friday (lunch-box ADR-0025); Friday alone keeps the line above.
  static String treatsOn(Set<int> treatDays) {
    if (TreatDaysShortcut.fridaysOnly.isChosenFor(treatDays)) {
      return treatsFridaysOnly;
    }
    final days = _and([
      for (final day in TreatDays.inOrder(treatDays)) AppCopy.weekdayName(day),
    ]);
    return 'Treats go in on $days, the days you chose. You can add one to any '
        'day on the lunch board.';
  }

  static String newForChild(int count) =>
      count == 0 ? 'Nothing new' : '$count new';
  static const originSuggested = 'Suggested';
  static const originFilled = 'Built on the phone';
  static const originSwapped = 'Your pick';
  static String swapTitle(String slot, String day) => '$slot on $day';
  static const leaveEmpty = 'Leave it empty';
  static const swapEveryDay = 'Every day this week';
  static String swapOption({
    required String idea,
    required Money price,
    required int boxesPerPack,
  }) => boxesPerPack <= 1
      ? '$idea · ${price.display}'
      : '$idea · ${price.display} · about $boxesPerPack lunches a pack · '
            '${Money((price.cents / boxesPerPack).round(), currency: price.currency).display} a lunch';
  static const basketHeadline = 'The basket';
  static const basketBody =
      'Every child’s new lunches together, in whole packs — what you’d pay '
      'at the till.';
  static String alreadyPlanned(String amount, String week) =>
      'Counted with the $amount already planned for $week.';
  static String nothingNew(String week) => 'Nothing new for $week';
  static const useAction = 'Use this week';

  // ---- 5. done ----
  static const doneTitle = 'Your week is planned';
  static String doneBody(int lunches) =>
      '${_count(lunches, 'compartment', 'compartments')} packed.';
  static String skipped(int count) =>
      '${_count(count, 'thing was', 'things were')} left out — filled by '
      'somebody else meanwhile, or no longer right for a child.';
  static const pricesNotSaved =
      'The prices were not saved — premium may have lapsed. The lunches are '
      'in.';
  static String addToGroceries(int count) =>
      'Add ${_count(count, 'product', 'products')} to the grocery list';
  static String packs(int count) => _count(count, 'pack', 'packs');
  static String groceriesAdded(int count, ProductRetailer shop) => count == 0
      ? 'Everything was on the grocery list already.'
      : '${_count(count, 'product', 'products')} added to the grocery list, '
            'matched at ${_name(shop)}.';
  static const seeLunches = 'See the lunches';
  static const planAgain = 'Plan again';

  static String problem(PlanWeekProblem problem) => switch (problem) {
    PlanWeekProblem.planWeekOff => 'Planning the week is switched off for now.',
    PlanWeekProblem.lunchNotShared =>
      'You can look at lunches here, but not plan them.',
    PlanWeekProblem.nothingToPlan => 'Choose a child to plan for.',
    PlanWeekProblem.weekNotPlannable =>
      'That week has gone. Plan this week or next.',
    PlanWeekProblem.partlySaved =>
      'Some of the week could not be saved. The rest is in.',
  };

  /// Why the phone stood in. Twig is named in words, never shown, on a
  /// fallback (design-system ADR-0012, ADR-0014).
  static String _without(PlanFallbackReason reason) => switch (reason) {
    PlanFallbackReason.aiOff => 'Twig’s planning is paused for now.',
    PlanFallbackReason.aiLimitReached =>
      'Twig’s plans for this month are used up — they come back on the 1st.',
    PlanFallbackReason.aiUnavailable => 'Twig didn’t answer just now.',
    PlanFallbackReason.offline => 'You look offline.',
  };

  static String _allergen(Allergen? allergen) => switch (allergen) {
    final allergen? => FamilyCopy.allergenName(allergen).toLowerCase(),
    null => 'an allergen',
  };

  static String _and(List<String> words) => words.length < 2
      ? words.join()
      : '${words.sublist(0, words.length - 1).join(', ')} and ${words.last}';

  static String _name(ProductRetailer shop) => CheckersCopy.retailerName(shop);

  static String _possessive(ProductRetailer shop) {
    final name = _name(shop);
    return name.endsWith('s') ? '$name’' : '$name’s';
  }

  static String _count(int count, String one, String many) =>
      count == 1 ? '1 $one' : '$count $many';
}
