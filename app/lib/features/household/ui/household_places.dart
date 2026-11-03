import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/flags/feature_flags_controller.dart';
import '../../assistants/ui/assistants_link.dart';
import '../../nanny_hub/model/nanny_access.dart';
import '../../referrals/ui/referral_link.dart';
import '../../subscriptions/ui/plan_link.dart';
import '../../welcome_tour/model/tour_target.dart';
import '../../welcome_tour/ui/tour_anchor.dart';
import '../model/household_place.dart';
import '../model/household_view.dart';
import 'household_place_tile.dart';

/// Every place a household has beyond the four tabs in the bar, grouped by
/// what it is for, on the More tab (design-system ADR-0005) — each only for
/// somebody the household's grant and its switches let use it (household
/// ADR-0003), as [HouseholdPlace] decides for the welcome tour too
/// (welcome-tour ADR-0001). A section with nothing in it for this person is
/// not shown.
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
    final open = HouseholdPlace.openTo(
      view,
      context.watch<FeatureFlagsController>().flags,
    );

    final week = [
      // Stars and rewards are a parent's to run (todos ADR-0003).
      if (open.contains(HouseholdPlace.stars))
        HouseholdPlaceTile(place: HouseholdPlace.stars, view: view),
      // calendar V2: who is handling what this week (calendar ADR-0006) — the
      // family's adults only, while its switch is on.
      if (open.contains(HouseholdPlace.sharedWeek))
        HouseholdPlaceTile(place: HouseholdPlace.sharedWeek, view: view),
    ];

    final family = [
      // family-profiles: what each person eats, cannot eat and needs, for
      // whoever the `familyProfiles` grant lets see it (ADR-0002).
      if (open.contains(HouseholdPlace.familyProfiles))
        TourAnchor(
          target: TourTarget.moreFamily,
          child: HouseholdPlaceTile(
            place: HouseholdPlace.familyProfiles,
            view: view,
          ),
        ),
      // Live location: each person's own to share, and it ends on its own.
      if (open.contains(HouseholdPlace.whereWeAre))
        HouseholdPlaceTile(place: HouseholdPlace.whereWeAre, view: view),
      // co-parenting: a child in two homes (household ADR-0004), for the
      // family, behind its flag.
      if (open.contains(HouseholdPlace.twoHomes))
        HouseholdPlaceTile(place: HouseholdPlace.twoHomes, view: view),
    ];

    final home = [
      // nanny hub (nanny-hub ADR-0003): for a carer it is what the household
      // is for, and for a parent it is where the latest handover waits.
      if (open.contains(HouseholdPlace.nannyHub))
        HouseholdPlaceTile(place: HouseholdPlace.nannyHub, view: view),
      // home-care: a helper's own jobs, or all of them (home-care ADR-0001).
      if (open.contains(HouseholdPlace.homeCare))
        HouseholdPlaceTile(place: HouseholdPlace.homeCare, view: view),
      // The household's papers (documents ADR-0001), only for somebody
      // allowed to open them (household ADR-0003).
      if (open.contains(HouseholdPlace.documents))
        HouseholdPlaceTile(place: HouseholdPlace.documents, view: view),
      if (open.contains(HouseholdPlace.photoFrames))
        HouseholdPlaceTile(place: HouseholdPlace.photoFrames, view: view),
    ];

    // subscriptions and referrals (subscriptions ADR-0001, ADR-0002): for
    // family, who buy it; referrals only while switched on.
    final plan = [
      if (open.contains(HouseholdPlace.plan)) PlanLink(householdId: id),
      if (open.contains(HouseholdPlace.referrals))
        ReferralLink(householdId: id),
    ];

    final elsewhere = [
      if (open.contains(HouseholdPlace.assistants))
        AssistantsLink(householdId: id),
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
        if (elsewhere.isNotEmpty) ...[
          const SizedBox(height: NestSpace.xxl),
          const NestSectionHeader(title: AssistantsCopy.sectionMore),
          const SizedBox(height: NestSpace.md),
          ...elsewhere,
        ],
      ],
    );
  }
}
