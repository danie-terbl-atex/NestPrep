import '../../../shared/flags/feature_flag.dart';
import '../../../shared/flags/feature_flags.dart';
import '../../family_profiles/model/family_access.dart';
import '../../nanny_hub/model/nanny_access.dart';
import '../../two_homes/model/two_homes_access.dart';
import 'household_area.dart';
import 'household_view.dart';

/// Every place a household has beyond the bar's tabs, as the More tab lists
/// them (design-system ADR-0005), and who may open each — the one answer
/// the More tab and the welcome tour both read (welcome-tour ADR-0001), so
/// the tour can never describe a place a person cannot open (`ENG-01`).
///
/// It only decides what is offered. The rules refuse the data whatever this
/// says (`FE-04`).
enum HouseholdPlace {
  /// The family calendar, day by day — on More since the bar gave its place
  /// to Meals (design-system ADR-0015).
  week,

  /// Stars the kids earn and their rewards — a parent's to run (todos
  /// ADR-0003).
  stars,

  /// Who is handling what this week (calendar ADR-0006).
  sharedWeek,

  /// What each person eats, cannot eat and needs (family-profiles ADR-0002).
  familyProfiles,

  /// Where everybody is, while they share it — open to everybody.
  whereWeAre,

  /// A child in two homes (household ADR-0004).
  twoHomes,

  /// What a carer needs for a shift (nanny-hub ADR-0003).
  nannyHub,

  /// Cleaning jobs (home-care ADR-0001).
  homeCare,

  /// The household's papers (documents ADR-0001).
  documents,

  /// Plan and billing — family buy it (subscriptions ADR-0001).
  plan,

  /// Give a month, get a month (subscriptions ADR-0002).
  referrals;

  /// Whether [view]'s viewer is offered this place while [flags] stand.
  bool isOpenTo(HouseholdView view, FeatureFlags flags) {
    final permissions = view.permissions;
    return switch (this) {
      HouseholdPlace.week => permissions.canUse(HouseholdArea.calendar),
      HouseholdPlace.stars || HouseholdPlace.plan => permissions.isFamily,
      HouseholdPlace.sharedWeek =>
        permissions.isFamily && flags.isOn(FeatureFlag.mentalLoadView),
      HouseholdPlace.familyProfiles => FamilyAccess.of(view).isVisible,
      HouseholdPlace.whereWeAre => true,
      HouseholdPlace.twoHomes =>
        flags.isOn(FeatureFlag.coParenting) &&
            TwoHomesAccess.of(view).showsWayIn,
      HouseholdPlace.nannyHub => NannyAccess.of(view).canView,
      HouseholdPlace.homeCare => permissions.canUse(HouseholdArea.homeCare),
      HouseholdPlace.documents => permissions.canUse(HouseholdArea.documents),
      HouseholdPlace.referrals =>
        permissions.isFamily && flags.isOn(FeatureFlag.referralRewards),
    };
  }

  /// The places [view]'s viewer is offered, in this enum's order.
  static Set<HouseholdPlace> openTo(HouseholdView view, FeatureFlags flags) => {
    for (final place in values)
      if (place.isOpenTo(view, flags)) place,
  };
}
