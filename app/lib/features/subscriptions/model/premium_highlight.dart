import 'premium_feature.dart';

/// The areas of the Premium map as a family is told them (subscriptions
/// ADR-0008, ADR-0010): what the paywall and the plan screen list. Coarser
/// than [PremiumFeature], which is what was reached for and what a purchase
/// is counted against.
enum PremiumHighlight {
  lunches,
  recipes,
  shops,
  snaps,
  whereWeAre,
  nannyHub,
  homeCare,
  twoHomes,
  documents,
  keepsakes,
  assistants,
  household;

  /// The area [feature] belongs to; null for the plan screen's own way in.
  static PremiumHighlight? of(PremiumFeature feature) => switch (feature) {
    PremiumFeature.lunchBox ||
    PremiumFeature.lunchLearning ||
    PremiumFeature.prepList ||
    PremiumFeature.budgetMode ||
    PremiumFeature.lunchPhoto ||
    PremiumFeature.aiPlanning ||
    PremiumFeature.healthProfile => lunches,
    PremiumFeature.recipes || PremiumFeature.ownRecipes => recipes,
    PremiumFeature.shops || PremiumFeature.recipeShopping => shops,
    PremiumFeature.listScan || PremiumFeature.schoolLetter => snaps,
    PremiumFeature.familyLocation => whereWeAre,
    PremiumFeature.nannyHub => nannyHub,
    PremiumFeature.homeCare => homeCare,
    PremiumFeature.twoHomes => twoHomes,
    PremiumFeature.documents => documents,
    PremiumFeature.avatarCreate ||
    PremiumFeature.avatarPortrait ||
    PremiumFeature.avatarWardrobe ||
    PremiumFeature.avatarKeepsakes => keepsakes,
    PremiumFeature.assistants => assistants,
    PremiumFeature.householdSize || PremiumFeature.additionalChild => household,
    PremiumFeature.direct => null,
  };

  /// Every area, the one [feature] belongs to first.
  static List<PremiumHighlight> startingWith(PremiumFeature feature) {
    final first = of(feature);
    return [?first, ...values.where((highlight) => highlight != first)];
  }
}
