import '../../features/subscriptions/model/billing_store.dart';
import '../../features/subscriptions/model/premium_feature.dart';
import '../../features/subscriptions/model/premium_highlight.dart';
import '../../features/subscriptions/model/subscription_plan.dart';
import '../failure/app_failure.dart';
import 'legal_copy.dart';

/// Every word premium says (`FE-19`, subscriptions ADR-0001) — beside
/// `AppCopy` rather than inside it, because it is one feature's vocabulary
/// and the shared file is edited by every feature at once. `AppCopy.failure`
/// reaches [problem] and [premiumRequired] through one line each.
///
/// No price is ever written here: the store formats it (`ENG-20`).
abstract final class SubscriptionCopy {
  static const premium = 'Premium';

  /// Premium no store sold: a referral, a frame order or a gift
  /// (subscriptions ADR-0002, ADR-0003, ADR-0004).
  static String givenUntil(String date) => 'Free Premium until $date.';
  static const free = 'Free';

  // ---- how a Premium household is told (subscriptions ADR-0007) ----
  static const membershipTitle = 'nestprep Premium';
  static String membershipBody(String household) =>
      'Every part of nestprep, for everyone in $household.';

  // ---- the paywall ----
  static String headline(PremiumFeature feature) => switch (feature) {
    PremiumFeature.additionalChild => 'Room for every child',
    PremiumFeature.lunchLearning => 'Lunches that learn',
    PremiumFeature.prepList => 'Sunday prep, sorted',
    PremiumFeature.budgetMode => 'Lunches on a budget',
    PremiumFeature.lunchPhoto => 'Every lunch, photographed',
    PremiumFeature.recipeShopping => 'From recipe to trolley',
    PremiumFeature.familyLocation => 'Always know everyone got there',
    PremiumFeature.listScan => 'Snap the list, skip the typing',
    PremiumFeature.ownRecipes => 'Your family’s recipes, all in one place',
    PremiumFeature.avatarCreate => 'A new buddy whenever they dream one up',
    PremiumFeature.avatarPortrait => 'Your whole nest in one picture',
    PremiumFeature.lunchBox => 'Lunchboxes, sorted for the week',
    PremiumFeature.recipes => 'Recipes for every night of the week',
    PremiumFeature.shops => 'Your list, straight to your shop',
    PremiumFeature.avatarWardrobe => 'A wardrobe for every nestling',
    PremiumFeature.avatarKeepsakes => 'Every creation, kept',
    PremiumFeature.twoHomes => 'One child, two homes, one plan',
    PremiumFeature.nannyHub => 'Everything your nanny needs for the shift',
    PremiumFeature.homeCare => 'The home, looked after',
    PremiumFeature.documents => 'The family’s papers, safe in one place',
    PremiumFeature.assistants => 'NestPrep in Claude and ChatGPT',
    PremiumFeature.schoolLetter => 'Snap the school letter',
    PremiumFeature.healthProfile =>
      'Allergies and medication, where carers see them',
    PremiumFeature.householdSize => 'Room for the whole household',
    PremiumFeature.aiPlanning || PremiumFeature.direct => 'NestPrep Premium',
  };

  static String pitch(PremiumFeature feature) => switch (feature) {
    PremiumFeature.additionalChild =>
      'The free plan keeps one child’s profile. Premium plans lunches and '
          'keeps allergies for all of them.',
    PremiumFeature.lunchLearning =>
      'Mark what came home uneaten, and next week’s ideas lean towards what '
          'your children actually eat.',
    PremiumFeature.prepList =>
      'Everything the week’s lunchboxes need, gathered into one list to '
          'batch-prep on Sunday.',
    PremiumFeature.budgetMode =>
      'See what each box and the week cost, keep to a weekly budget, and '
          'get cheaper swaps your children will still eat.',
    PremiumFeature.lunchPhoto =>
      'See each lunchbox as a photo of the very foods you packed, made '
          'for your week.',
    PremiumFeature.recipeShopping =>
      'Find what a recipe still needs at your shop in one tap, then send '
          'it to your grocery list or straight to your cart.',
    PremiumFeature.listScan =>
      'Take a photo of any shopping list and every item lands on your grocery '
          'list — or straight onto your cart at your shop.',
    PremiumFeature.ownRecipes =>
      'Type them in, paste a link or snap a photo. They plan, shop and cook '
          'like every other recipe, for your household only.',
    PremiumFeature.avatarCreate =>
      'Turn drawings, pets and made-up buddies into pictures 12 times a '
          'month, each kept beside the drawing it came from.',
    PremiumFeature.avatarPortrait =>
      'Everyone’s characters together in one picture for the season, '
          'straight onto your frame’s slideshow.',
    PremiumFeature.familyLocation =>
      'See where everybody is on one map, share all day without opening '
          'the app, and hear when they reach school or home.',
    PremiumFeature.lunchBox =>
      'Plan every child’s lunchboxes for the week, within their '
          'allergies and school rules, and fill the week in a tap.',
    PremiumFeature.recipes =>
      'Browse the whole recipe book, save your own, and plan any of '
          'them into your week.',
    PremiumFeature.shops =>
      'Find everything on your list at your shop, compare the basket, '
          'and fill your own cart in a tap.',
    PremiumFeature.avatarWardrobe =>
      'Hats, glasses and more for each character, with a star shop '
          'the children can save up for.',
    PremiumFeature.avatarKeepsakes =>
      'Every picture your family makes, kept beside the drawing it '
          'came from.',
    PremiumFeature.twoHomes =>
      'Share the schedule, the handovers and what matters between '
          'both homes.',
    PremiumFeature.nannyHub =>
      'Child cards, an emergency sheet, the house guide, shift logs '
          'and photo updates for the people who care for your children.',
    PremiumFeature.homeCare =>
      'Cleaning jobs with photos, routines, stock and instructions in '
          'your helper’s language.',
    PremiumFeature.documents =>
      'Shared folders for the household’s papers, and a private vault '
          'for each person’s IDs behind your phone’s lock.',
    PremiumFeature.assistants =>
      'Ask your assistant to add an event or put something on the '
          'list, and it lands in your household.',
    PremiumFeature.schoolLetter =>
      'Take a photo of a school letter and its dates land on your '
          'calendar, ready to check.',
    PremiumFeature.healthProfile =>
      'Record each person’s allergies and medication, so lunches stay '
          'safe and carers know what matters.',
    PremiumFeature.householdSize =>
      'The free plan has room for four people. Premium has room for '
          'everybody.',
    PremiumFeature.aiPlanning || PremiumFeature.direct =>
      'Take more of the planning off the family’s plate.',
  };

  static const paywallLabel = 'Premium';
  static const seePremium = 'See Premium';
  static const lockedHint = 'Part of Premium';
  static const close = 'Close';
  static const everything = 'Everything in Premium';
  static const reachedFor = 'You’re here for this';
  static const wholeHousehold = 'One plan covers everyone in your household.';

  static String highlightTitle(PremiumHighlight highlight) =>
      switch (highlight) {
        PremiumHighlight.lunches => 'Lunchboxes',
        PremiumHighlight.recipes => 'Recipes',
        PremiumHighlight.shops => 'Your shops',
        PremiumHighlight.snaps => 'Snap it',
        PremiumHighlight.whereWeAre => 'Where we are',
        PremiumHighlight.nannyHub => 'Nanny hub',
        PremiumHighlight.homeCare => 'Home care',
        PremiumHighlight.twoHomes => 'Two homes',
        PremiumHighlight.documents => 'Documents',
        PremiumHighlight.keepsakes => 'Keepsakes',
        PremiumHighlight.assistants => 'Assistants',
        PremiumHighlight.household => 'Room for everyone',
      };

  static String highlightBody(
    PremiumHighlight highlight,
  ) => switch (highlight) {
    PremiumHighlight.lunches =>
      'A week of lunches for every child, within allergies and school '
          'rules',
    PremiumHighlight.recipes => 'The whole recipe book, plus your family’s own',
    PremiumHighlight.shops => 'Your list, straight into your cart at your shop',
    PremiumHighlight.snaps =>
      'A photo of a shopping list or a school letter, read for you',
    PremiumHighlight.whereWeAre =>
      'Everyone on one map, and a nudge when they arrive',
    PremiumHighlight.nannyHub =>
      'Child cards, the house guide, shift logs and photo updates',
    PremiumHighlight.homeCare =>
      'Cleaning jobs, routines and stock, in your helper’s language',
    PremiumHighlight.twoHomes =>
      'One schedule and calm handovers between both homes',
    PremiumHighlight.documents => 'Shared folders, and a private vault for IDs',
    PremiumHighlight.keepsakes =>
      'Drawings and pets turned into characters, every one kept',
    PremiumHighlight.assistants =>
      'Add events and groceries from Claude or ChatGPT',
    PremiumHighlight.household => 'More than four people in one household',
  };

  static const choosePlan = 'Choose a plan';
  static String planName(SubscriptionPlan plan) => switch (plan) {
    SubscriptionPlan.monthly => 'Monthly',
    SubscriptionPlan.yearly => 'Yearly',
  };

  static String perPeriod(SubscriptionPlan plan) => switch (plan) {
    SubscriptionPlan.monthly => 'a month',
    SubscriptionPlan.yearly => 'a year',
  };

  static String saving(int percent) => 'Save $percent%';
  static const suggested = 'Suggested';

  /// What a screen reader says for a plan card.
  static String planLabel({
    required SubscriptionPlan plan,
    required String price,
  }) => '${planName(plan)}, $price ${perPeriod(plan)}';

  static const subscribe = 'Start Premium';
  static const openingStore = 'Opening the store…';
  static const unlocking = 'Unlocking premium…';
  static const restore = 'Restore purchases';
  static const restoring = 'Looking for your purchase…';

  static String smallPrint(BillingStore? store) =>
      'Paid through ${storeName(store)}. It renews by itself until you '
      'cancel it there, and everyone in your household has premium.';

  static String storeName(BillingStore? store) => switch (store) {
    BillingStore.appStore => 'the App Store',
    BillingStore.playStore => 'Google Play',
    null => 'your phone’s store',
  };

  static const askAParent =
      'Premium is bought by a parent. Ask one of them to upgrade — it covers '
      'everyone in the household.';

  static const notYetTitle = 'Premium isn’t available yet';
  static const notYetBody =
      'It is on its way. Everything on the free plan keeps working as it '
      'does now.';

  static const awaitingApproval =
      'Waiting for approval. Premium unlocks as soon as the purchase goes '
      'through.';

  static const welcomeCheer = 'Welcome to Premium';
  static const welcomeTitle = 'You’re on Premium';
  static const welcomeBody =
      'Thank you. Everyone in your household has it now.';
  static const done = 'Done';
  static const notNow = 'Not now';

  // ---- the plan screen ----
  static const planTitle = 'Plan & billing';
  static const openFromHousehold = 'Plan & billing';
  static String openFromHouseholdBody({required bool isPremium}) =>
      isPremium ? 'Premium for the whole household' : 'Free plan · see Premium';

  static const freeSummary =
      'Free for as long as you like. Premium adds more when you want it.';
  static String renewsOn(String date) => 'Renews on $date';
  static String endsOn(String date) => 'Ends on $date';
  static String graceUntil(String date) =>
      'The store couldn’t take the last payment. Premium carries on until '
      '$date while it tries again.';
  static const onHold =
      'Premium is paused: the store couldn’t take the payment. Update it in '
      'your store account and it comes back.';
  static const lapsed = 'Premium has ended.';
  static const refunded = 'Premium was refunded.';
  static const keptSafe =
      'Everything your household made is still here. Adding another child and '
      'the premium features wait until premium is back.';

  static String managedBy(String name, BillingStore? store) =>
      'Bought by $name through ${storeName(store)}.';
  static String onlyBuyerManages(String name) =>
      'Only $name can change or cancel it, from their own store account.';
  static const someoneElse = 'someone in your household';
  static const storeTest = 'Store test';

  static const whatYouHave = 'On the free plan';
  static const freeCalendar = 'The family calendar';
  static const freeLists = 'Shared lists, to-dos and meals';
  static const freeFourPeople = 'Room for four people';
  static const whatPremiumAdds = 'What Premium adds';
  static const upgrade = 'See Premium';
  static const manage = 'Manage subscription';
  static const restoreHint =
      'Bought premium before, or on another phone? Restore it here.';

  // ---- refusals (`FE-09`) ----
  static String premiumRequired(PremiumFeature feature) => switch (feature) {
    PremiumFeature.additionalChild =>
      'The free plan has room for one child. Premium adds the rest.',
    PremiumFeature.householdSize =>
      'The free plan has room for four people. Premium adds the rest.',
    _ => 'That is part of Premium.',
  };

  static String problem(SubscriptionProblem problem) => switch (problem) {
    SubscriptionProblem.onlyFamilyCanBuy => askAParent,
    SubscriptionProblem.premiumUnavailable => notYetTitle,
    SubscriptionProblem.storeUnreachable =>
      'Your purchase went through, and we couldn’t reach the store to '
          'confirm it. We’ll try again next time NestPrep opens.',
    SubscriptionProblem.purchaseNotValid =>
      'That purchase couldn’t be confirmed with the store. Try Restore '
          'purchases; if it still fails, the store can refund it.',
    SubscriptionProblem.purchaseInUseElsewhere =>
      'That subscription already gives another household premium.',
    SubscriptionProblem.guardianConsentRequired =>
      LegalCopy.guardianConsentNeeded,
    SubscriptionProblem.storeNotAvailable =>
      'This phone can’t reach a store to buy from. Try again on a phone '
          'signed in to its store.',
    SubscriptionProblem.productsNotFound =>
      'Premium isn’t in the store yet. Try again later.',
    SubscriptionProblem.purchaseFailed =>
      'The store couldn’t take the payment. Nothing was charged.',
    SubscriptionProblem.nothingToRestore =>
      'There is no active NestPrep subscription on this store account.',
  };
}
