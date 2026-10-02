import '../../features/family_profiles/model/allergen.dart';
import '../../features/plan_week/model/left_out_reason.dart';
import '../../features/plan_week/model/plan_fallback.dart';
import '../failure/app_failure.dart';
import 'family_copy.dart';

/// Every word *Plan my week from Checkers* says (`FE-19`, lunch-box
/// ADR-0012). Each step says what it is doing and what NestPrep decided.
abstract final class PlanWeekCopy {
  // ---- the way in, on the lunch board ----
  static const entryTitle = 'Plan my week from Checkers';
  static const entryBody =
      'Lunches for every child, from what Checkers sells — within your '
      'budget, one step at a time.';
  static const entryAction = 'Plan my week';
  static const premiumTag = 'Premium';

  // ---- the steps ----
  static const title = 'Plan my week';
  static const stepNames = [
    'Brief',
    'Ideas',
    'At Checkers',
    'The week',
    'Done',
  ];
  static String stepOf(int number, String name) =>
      'Step $number of ${stepNames.length}: $name';
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
  static const shopHeader = 'Shop';
  static String shopNear(String area) => 'Checkers Sixty60 near $area';
  static const shopNearYou = 'Checkers Sixty60 near you';
  static const shopFinding = 'Finding your nearest Checkers…';
  static const shopOnly = 'Checkers is the only shop for now.';
  static const changeArea = 'Change area';
  static const budgetHeader = 'Weekly lunch budget';
  static const budgetBody =
      'For every child’s lunches together — what you’d pay at the till.';
  static String budgetIs(String amount) => '$amount a week';
  static const noBudget =
      'No budget yet. The plan still says what the basket costs.';
  static const setBudget = 'Set a budget';
  static const changeBudget = 'Change the budget';
  static const draftAction = 'Get lunch ideas';

  // ---- 2. ideas ----
  static const aisleTitle = 'Walking the lunchbox aisle…';
  static const aisleLine =
      'Reading Checkers’ own Kids Lunchbox shelves near you and checking '
      'every product against each child’s rules.';
  static String aisleProgress(int read, int total) =>
      'Shelf ${read < total ? read + 1 : total} of $total';
  static const draftingTitle = 'Thinking up lunch ideas…';
  static const draftingLine =
      'Reading what each child likes and eats, the open compartments and the '
      'budget.';
  static const ideasHeadline = 'What we’ll look for at Checkers';
  static const ideasBody =
      'Remove anything you don’t want, or add your own. Struck-out ideas were '
      'left out by NestPrep for the reason shown.';
  static const madeByAi = 'Ideas from AI';
  static const madeWithoutAi = 'Ideas from your usuals';
  static String fallbackIdeas(PlanFallbackReason reason) =>
      '${_without(reason)} So these ideas come from your own lunch library.';
  static String callsLeft(int calls) => switch (calls) {
    0 => 'That was this month’s last AI call.',
    1 => '1 AI call left this month.',
    _ => '$calls AI calls left this month.',
  };
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
  static const originAisle = 'Checkers lunchbox aisle';
  static String shelfKept(int count) =>
      '${_count(count, 'product', 'products')} kept from this shelf';
  static const shelfNothingKept = 'Nothing on this shelf suits anyone';
  static String aisleUnread(int count) =>
      '${_count(count, 'shelf', 'shelves')} of the lunchbox aisle could not '
      'be read, so the other ideas are searched instead.';
  static const noIdeas = 'No ideas left to look for';
  static const noIdeasBody = 'Add one of your own, or go back and try again.';
  static String searchAction(int count) =>
      'Look for ${_count(count, 'idea', 'ideas')} at Checkers';

  // ---- the lunchbox aisle's shelves (lunch-box ADR-0013) ----
  static const shelfTummyFillers = 'Tummy fillers';
  static const shelfCrunchTheColours = 'Crunch the colours';
  static const shelfBabyVeg = 'Baby veg';
  static const shelfYoghurtSnackTime = 'Yoghurt snack time';
  static const shelfUnwrapASmile = 'Unwrap a smile';
  static const shelfJunkFreeFillers = '100% junk-free fillers';
  static const shelfMindfulSnacking = 'Mindful snacking';
  static const shelfSqueezeSnackGo = 'Squeeze. Snack. Go';
  static const shelfFreshlyBaked = 'Freshly baked';
  static const shelfProteinFillers = 'Protein fillers';
  static const shelfDriedFruitAndNuts = 'Dried fruit and nuts';
  static const shelfCookiesAndBiscuits = 'Cookies, chippies and biscuits';

  // ---- 3. at the shop ----
  static const storeHeadline = 'Looking at Checkers';
  static const storeBody =
      'One idea at a time. Every product is checked against each child’s '
      'rules; anything left out says why.';
  static const waiting = 'Waiting';
  static const searching = 'Searching…';
  static String found(int found, int kept) => '$found found · $kept kept';
  static const nothingFound = 'Checkers has nothing by that name.';
  static String showLeftOut(int count) =>
      'Show ${_count(count, 'product', 'products')} left out';
  static const hideLeftOut = 'Hide';
  static const nothingKept =
      'Nothing was kept yet. Go back and try other ideas.';
  static const buildAction = 'Build the week';

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
  static const buildingLine =
      'Choosing from what Checkers had, for each child, within the budget.';
  static const weekHeadline = 'Your week';
  static const builtByAi = 'Built with AI';
  static const builtWithoutAi = 'Built without AI';
  static String fallbackWeek(PlanFallbackReason reason) =>
      '${_without(reason)} So the phone built it: the cheapest kept product '
      'for each idea, ideas taken in turn.';
  static String dropped(int count) =>
      '${_count(count, 'choice was', 'choices were')} left out because it '
      'did not fit a child’s rules.';
  static const alreadyPacked = 'Already packed';
  static const tapToSwap = 'Tap anything new to swap it or clear it.';
  static String newForChild(int count) =>
      count == 0 ? 'Nothing new' : '$count new';
  static const originSuggested = 'Suggested';
  static const originFilled = 'Built on the phone';
  static const originSwapped = 'Your pick';
  static String swapTitle(String slot, String day) => '$slot on $day';
  static const leaveEmpty = 'Leave it empty';
  static String perPack(int boxes) =>
      'A pack does ${_count(boxes, 'box', 'boxes')}';
  static const basketHeadline = 'The basket';
  static const basketBody =
      'Every child’s new lunches together, in whole packs — what you’d pay '
      'at the till.';
  static const nothingNew = 'Nothing new for this week';
  static const nothingNewBody =
      'Every compartment is packed already, or nothing kept fits. Go back and '
      'try other ideas.';
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
  static String groceriesAdded(int count) => count == 0
      ? 'Everything was on the grocery list already.'
      : '${_count(count, 'product', 'products')} added to the grocery list, '
            'matched at Checkers.';
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

  static String _without(PlanFallbackReason reason) => switch (reason) {
    PlanFallbackReason.aiOff => 'AI planning is paused.',
    PlanFallbackReason.aiLimitReached =>
      'This month’s AI calls are used up — they come back on the 1st.',
    PlanFallbackReason.aiUnavailable => 'The AI did not answer.',
    PlanFallbackReason.offline => 'You look offline.',
  };

  static String _allergen(Allergen? allergen) => switch (allergen) {
    final allergen? => FamilyCopy.allergenName(allergen).toLowerCase(),
    null => 'an allergen',
  };

  static String _count(int count, String one, String many) =>
      count == 1 ? '1 $one' : '$count $many';
}
