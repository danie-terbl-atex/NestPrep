import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/calendar_v2_route.dart';
import '../../../app/chore_points_route.dart';
import '../../../app/documents_route.dart';
import '../../../app/family_route.dart';
import '../../../app/home_care_route.dart';
import '../../../app/household_route.dart';
import '../../../app/nanny_hub_route.dart';
import '../../../app/photo_frame_route.dart';
import '../../../app/two_homes_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/points_copy.dart';
import '../model/household_area.dart';
import '../model/household_place.dart';
import '../model/household_view.dart';

/// A place that opens as a tile and pushes its screen (`FE-17`). Plan,
/// referrals and assistants are links, not tiles.
class HouseholdPlaceTile extends StatelessWidget {
  const HouseholdPlaceTile({
    required this.place,
    required this.view,
    super.key,
  });

  final HouseholdPlace place;
  final HouseholdView view;

  @override
  Widget build(BuildContext context) {
    final id = view.household.id;
    final (icon, tint, title, subtitle, path) = switch (place) {
      HouseholdPlace.stars => (
        LucideIcons.sparkles,
        NestTileTint.butter,
        PointsCopy.screenTitle,
        MoreCopy.starsBody,
        ChorePointsRoute.pathFor(id),
      ),
      HouseholdPlace.sharedWeek => (
        LucideIcons.handHeart,
        NestTileTint.guava,
        MentalLoadCopy.openFromHousehold,
        MentalLoadCopy.openFromHouseholdBody,
        CalendarV2Route.sharedWeekPathFor(id),
      ),
      HouseholdPlace.familyProfiles => (
        LucideIcons.users,
        NestTileTint.guava,
        FamilyCopy.openFromHousehold,
        FamilyCopy.openFromHouseholdBody,
        FamilyRoute.pathFor(id),
      ),
      HouseholdPlace.whereWeAre => (
        LucideIcons.mapPin,
        NestTileTint.lilac,
        LocationCopy.title,
        MoreCopy.locationBody,
        HouseholdRoute.wherePathFor(id),
      ),
      HouseholdPlace.twoHomes => (
        LucideIcons.house,
        NestTileTint.butter,
        TwoHomesCopy.openFromHousehold,
        TwoHomesCopy.openFromHouseholdBody,
        TwoHomesRoute.pathFor(id),
      ),
      HouseholdPlace.nannyHub => (
        LucideIcons.baby,
        NestTileTint.basil,
        NannyCopy.openFromHousehold,
        NannyCopy.openFromHouseholdBody,
        NannyHubRoute.pathFor(id),
      ),
      HouseholdPlace.homeCare => (
        LucideIcons.sprayCan,
        NestTileTint.lilac,
        HomeCareCopy.openFromHousehold,
        view.permissions.canEdit(HouseholdArea.homeCare)
            ? HomeCareCopy.openFromHouseholdBody
            : HomeCareCopy.openFromHouseholdHelperBody,
        HomeCareRoute.pathFor(id),
      ),
      HouseholdPlace.documents => (
        LucideIcons.folderOpen,
        NestTileTint.accent,
        AppCopy.documentsOpenLibrary,
        MoreCopy.documentsBody,
        DocumentsRoute.pathFor(id),
      ),
      HouseholdPlace.photoFrames => (
        LucideIcons.tvMinimal,
        NestTileTint.butter,
        PhotoFrameCopy.title,
        PhotoFrameCopy.openFromHouseholdBody,
        PhotoFrameRoute.pathFor(id),
      ),
      HouseholdPlace.plan ||
      HouseholdPlace.referrals ||
      HouseholdPlace.assistants => throw StateError('$place is not a tile'),
    };
    return NestPlaceTile(
      icon: icon,
      tint: tint,
      title: title,
      subtitle: subtitle,
      onTap: () => context.push(path),
    );
  }
}
