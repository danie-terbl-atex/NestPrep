import '../../features/subscriptions/model/billing_store.dart';
import '../../features/subscriptions/model/premium_feature.dart';
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

  /// Premium no store sold: a month from give a month, get a month
  /// (subscriptions ADR-0002).
  static String givenUntil(String date) =>
      'A free month from a referral, until $date.';
  static const free = 'Free';

  // ---- the paywall ----
  static String headline(PremiumFeature feature) => switch (feature) {
    PremiumFeature.additionalChild => 'Room for every child',
    PremiumFeature.lunchLearning => 'Lunches that learn',
    PremiumFeature.prepList => 'Sunday prep, sorted',
    PremiumFeature.budgetMode => 'Lunches on a budget',
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
    PremiumFeature.aiPlanning || PremiumFeature.direct =>
      'Take more of the planning off the family’s plate.',
  };

  static const paywallLabel = 'Premium';
  static const benefitChildren = 'Every child’s lunches and profile';
  static const benefitChildrenBody = 'Allergies and likes for each of them';
  static const benefitLearning = 'Learns what gets eaten';
  static const benefitLearningBody = 'Suggestions lean on what came home empty';
  static const benefitPrep = 'The Sunday prep list';
  static const benefitPrepBody = 'The week’s lunch prep in one place';
  static const benefitHousehold = 'One plan, the whole household';
  static const benefitHouseholdBody = 'Everyone you share NestPrep with has it';

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
  static const freeOneChild = 'One child’s profile';
  static const whatPremiumAdds = 'What Premium adds';
  static const upgrade = 'See Premium';
  static const manage = 'Manage subscription';
  static const restoreHint =
      'Bought premium before, or on another phone? Restore it here.';

  // ---- refusals (`FE-09`) ----
  static String premiumRequired(PremiumFeature feature) => switch (feature) {
    PremiumFeature.additionalChild =>
      'The free plan has room for one child. Premium adds the rest.',
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
