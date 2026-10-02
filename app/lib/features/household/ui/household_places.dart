import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/calendar_v2_route.dart';
import '../../../app/chore_points_route.dart';
import '../../../app/documents_route.dart';
import '../../../app/family_route.dart';
import '../../../app/home_care_route.dart';
import '../../../app/household_route.dart';
import '../../../app/household_shell.dart';
import '../../../app/nanny_hub_route.dart';
import '../../../app/two_homes_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/points_copy.dart';
import '../../../shared/flags/feature_flag.dart';
import '../../../shared/flags/feature_flags_controller.dart';
import '../../family_profiles/model/family_access.dart';
import '../../nanny_hub/model/nanny_access.dart';
import '../../referrals/ui/referral_link.dart';
import '../../referrals/ui/referrals_offered.dart';
import '../../subscriptions/ui/plan_link.dart';
import '../../two_homes/model/two_homes_access.dart';
import '../model/household_area.dart';
import '../model/household_view.dart';

/// Every place a household has beyond the four tabs in the bar, grouped by
/// what it is for, on the More tab (design-system ADR-0005) — each only for
/// somebody the household's grant and its switches let use it (household
/// ADR-0003). A section with nothing in it for this person is not shown.
///
/// Every tile **pushes**: each place is a detail of More, so back comes back
/// here rather than closing the app (`FE-17`).
class HouseholdPlaces extends StatelessWidget {
  const HouseholdPlaces({required this.view, super.key});

  final HouseholdView view;

  @override
  Widget build(BuildContext context) {
    final id = view.household.id;
    final permissions = view.permissions;
    final flags = context.watch<FeatureFlagsController>();
    void open(String path) => context.push(path);

    final week = [
      if (permissions.canUse(HouseholdArea.meals))
        NestPlaceTile(
          icon: Icons.restaurant_outlined,
          tint: NestTileTint.basil,
          title: AppCopy.tabMeals,
          subtitle: MoreCopy.mealsBody,
          onTap: () => open(HouseholdRoute.pathFor(id, HouseholdTab.meals)),
        ),
      // Stars and rewards are a parent's to run (todos ADR-0003).
      if (permissions.isFamily)
        NestPlaceTile(
          icon: Icons.stars_outlined,
          tint: NestTileTint.butter,
          title: PointsCopy.screenTitle,
          subtitle: MoreCopy.starsBody,
          onTap: () => open(ChorePointsRoute.pathFor(id)),
        ),
      // calendar V2: who is handling what this week (calendar ADR-0006) — the
      // family's adults only, while its switch is on.
      if (permissions.isFamily && flags.isOn(FeatureFlag.mentalLoadView))
        NestPlaceTile(
          icon: Icons.volunteer_activism_outlined,
          tint: NestTileTint.guava,
          title: MentalLoadCopy.openFromHousehold,
          subtitle: MentalLoadCopy.openFromHouseholdBody,
          onTap: () => open(CalendarV2Route.sharedWeekPathFor(id)),
        ),
    ];

    final family = [
      // family-profiles: what each person eats, cannot eat and needs, for
      // whoever the `familyProfiles` grant lets see it (ADR-0002).
      if (FamilyAccess.of(view).isVisible)
        NestPlaceTile(
          icon: Icons.family_restroom_outlined,
          tint: NestTileTint.guava,
          title: FamilyCopy.openFromHousehold,
          subtitle: FamilyCopy.openFromHouseholdBody,
          onTap: () => open(FamilyRoute.pathFor(id)),
        ),
      // Live location: each person's own to share, and it ends on its own.
      NestPlaceTile(
        icon: Icons.person_pin_circle_outlined,
        tint: NestTileTint.lilac,
        title: AppCopy.locationTitle,
        subtitle: MoreCopy.locationBody,
        onTap: () => open(HouseholdRoute.wherePathFor(id)),
      ),
      // co-parenting: a child in two homes (household ADR-0004), for the
      // family, behind its flag.
      if (flags.isOn(FeatureFlag.coParenting) &&
          TwoHomesAccess.of(view).showsWayIn)
        NestPlaceTile(
          icon: Icons.cottage_outlined,
          tint: NestTileTint.butter,
          title: TwoHomesCopy.openFromHousehold,
          subtitle: TwoHomesCopy.openFromHouseholdBody,
          onTap: () => open(TwoHomesRoute.pathFor(id)),
        ),
    ];

    final home = [
      // nanny hub (nanny-hub ADR-0003): for a carer it is what the household
      // is for, and for a parent it is where the latest handover waits.
      if (NannyAccess.of(view).canView)
        NestPlaceTile(
          icon: Icons.child_care,
          tint: NestTileTint.basil,
          title: NannyCopy.openFromHousehold,
          subtitle: NannyCopy.openFromHouseholdBody,
          onTap: () => open(NannyHubRoute.pathFor(id)),
        ),
      // home-care: a helper's own jobs, or all of them (home-care ADR-0001).
      if (permissions.canUse(HouseholdArea.homeCare))
        NestPlaceTile(
          icon: Icons.cleaning_services_outlined,
          tint: NestTileTint.lilac,
          title: HomeCareCopy.openFromHousehold,
          subtitle: permissions.canEdit(HouseholdArea.homeCare)
              ? HomeCareCopy.openFromHouseholdBody
              : HomeCareCopy.openFromHouseholdHelperBody,
          onTap: () => open(HomeCareRoute.pathFor(id)),
        ),
      // The household's papers (documents ADR-0001), only for somebody
      // allowed to open them (household ADR-0003).
      if (permissions.canUse(HouseholdArea.documents))
        NestPlaceTile(
          icon: Icons.folder_shared_outlined,
          title: AppCopy.documentsOpenLibrary,
          subtitle: MoreCopy.documentsBody,
          onTap: () => open(DocumentsRoute.pathFor(id)),
        ),
    ];

    // subscriptions and referrals (subscriptions ADR-0001, ADR-0002): for
    // family, who buy it; referrals only while switched on.
    final plan = [
      if (permissions.isFamily) PlanLink(householdId: id),
      if (referralsOffered(context)) ReferralLink(householdId: id),
    ];

    final isCarer = !permissions.isFamily && NannyAccess.of(view).canView;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // For a carer the hub is what the household is for, so the section
        // it opens comes first (nanny-hub ADR-0003); for family, the order a
        // week uses them.
        for (final (title, tiles) in [
          if (isCarer) (MoreCopy.sectionHome, home),
          (MoreCopy.sectionWeek, week),
          (MoreCopy.sectionFamily, family),
          if (!isCarer) (MoreCopy.sectionHome, home),
        ])
          if (tiles.isNotEmpty) ...[
            const SizedBox(height: NestSpace.xxl),
            NestSectionHeader(title: title),
            const SizedBox(height: NestSpace.md),
            NestPlaceGrid(children: tiles),
          ],
        if (plan.isNotEmpty) ...[
          const SizedBox(height: NestSpace.xxl),
          const NestSectionHeader(title: MoreCopy.sectionPlan),
          const SizedBox(height: NestSpace.md),
          for (final (index, link) in plan.indexed) ...[
            if (index > 0) const SizedBox(height: NestSpace.md),
            link,
          ],
        ],
      ],
    );
  }
}
