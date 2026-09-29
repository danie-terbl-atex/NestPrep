import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/documents_route.dart';
import '../../../app/family_route.dart';
import '../../../app/home_care_route.dart';
import '../../../app/household_route.dart';
import '../../../app/nanny_hub_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../family_profiles/model/family_access.dart';
import '../../nanny_hub/model/nanny_access.dart';
import '../../referrals/ui/referral_link.dart';
import '../../referrals/ui/referrals_offered.dart';
import '../../subscriptions/ui/plan_link.dart';
import '../model/household_area.dart';
import '../model/household_view.dart';

/// The places that hang off the household screen rather than the bottom bar,
/// which stays at the four things a household does in a week: family
/// profiles, where everybody is, and the household's papers — each only for
/// somebody the household's grant lets use it (household ADR-0003).
class HouseholdPlaces extends StatelessWidget {
  const HouseholdPlaces({required this.view, super.key});

  final HouseholdView view;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // nanny hub (nanny-hub ADR-0003): first, because for a carer it is
        // what the household screen is for, and for a parent it is where the
        // latest handover waits.
        if (NannyAccess.of(view).canView) ...[
          NestCard(
            variant: NestCardVariant.tinted,
            padding: EdgeInsets.zero,
            child: NestListRow(
              title: NannyCopy.openFromHousehold,
              subtitle: NannyCopy.openFromHouseholdBody,
              leading: const NestIconTile(
                icon: Icons.child_care,
                tint: NestTileTint.mint,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () =>
                  context.push(NannyHubRoute.pathFor(view.household.id)),
            ),
          ),
          const SizedBox(height: NestSpace.lg),
        ],
        // family-profiles: what each person eats, cannot eat and needs. It
        // hangs off the people it is about (family-profiles ADR-0001), for
        // whoever the `familyProfiles` grant lets see it (ADR-0002).
        if (FamilyAccess.of(view).isVisible) ...[
          NestCard(
            variant: NestCardVariant.flat,
            padding: EdgeInsets.zero,
            child: NestListRow(
              title: FamilyCopy.openFromHousehold,
              subtitle: FamilyCopy.openFromHouseholdBody,
              leading: const NestIconTile(
                icon: Icons.family_restroom_outlined,
                tint: NestTileTint.pink,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(FamilyRoute.pathFor(view.household.id)),
            ),
          ),
          const SizedBox(height: NestSpace.lg),
        ],
        // home-care: cleaning jobs, for whoever the `homeCare` grant lets
        // see them — a helper's own jobs, or all of them (home-care
        // ADR-0001).
        if (view.permissions.canUse(HouseholdArea.homeCare)) ...[
          NestCard(
            variant: NestCardVariant.flat,
            padding: EdgeInsets.zero,
            child: NestListRow(
              title: HomeCareCopy.openFromHousehold,
              subtitle: view.permissions.canEdit(HouseholdArea.homeCare)
                  ? HomeCareCopy.openFromHouseholdBody
                  : HomeCareCopy.openFromHouseholdHelperBody,
              leading: const NestIconTile(
                icon: Icons.cleaning_services_outlined,
                tint: NestTileTint.mint,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () =>
                  context.push(HomeCareRoute.pathFor(view.household.id)),
            ),
          ),
          const SizedBox(height: NestSpace.lg),
        ],
        // subscriptions: which plan the household is on, and the way to
        // premium (subscriptions ADR-0001) — for family, who buy it.
        if (view.permissions.isFamily) ...[
          PlanLink(householdId: view.household.id),
          const SizedBox(height: NestSpace.lg),
        ],
        // referrals: give a month, get a month, beside the plan
        // (subscriptions ADR-0002) — for family, while switched on.
        if (referralsOffered(context)) ...[
          ReferralLink(householdId: view.household.id),
          const SizedBox(height: NestSpace.lg),
        ],
        // The way to the live-location screen. It sits with the people rather
        // than in the bottom bar, and says what it is before it is tapped —
        // that sharing is each person's own, and ends on its own.
        NestListRow(
          leading: const NestIconTile(icon: Icons.person_pin_circle_outlined),
          title: AppCopy.locationTitle,
          subtitle: AppCopy.locationYoursBody,
          trailing: Icon(
            Icons.chevron_right,
            size: NestSize.iconMedium,
            color: NestTheme.of(context).colors.inkTertiary,
          ),
          onTap: () =>
              context.push(HouseholdRoute.wherePathFor(view.household.id)),
        ),
        const SizedBox(height: NestSpace.lg),
        // The household's papers hang off this screen rather than the bottom
        // bar, which stays at the four things a household does in a week
        // (documents ADR-0001) — and only for somebody allowed to open them
        // (household ADR-0003).
        if (view.permissions.canUse(HouseholdArea.documents))
          NestCard(
            variant: NestCardVariant.flat,
            padding: EdgeInsets.zero,
            child: NestListRow(
              title: AppCopy.documentsOpenLibrary,
              subtitle: AppCopy.documentsEmptyBody,
              leading: const NestIconTile(
                icon: Icons.folder_shared_outlined,
                tint: NestTileTint.sky,
              ),
              trailing: const Icon(Icons.chevron_right),
              // Pushed, not gone to: this opens *over* the household screen, so
              // back lands here rather than closing the app (`FE-17`).
              onTap: () =>
                  context.push(DocumentsRoute.pathFor(view.household.id)),
            ),
          ),
      ],
    );
  }
}
